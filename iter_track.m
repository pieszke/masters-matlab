addpath("helpers","helpers\nextname")

rootDir = 'C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST';

% Filtr grup pomiarowych
groupFilter = 'hall';    % np. '', '310_side', '310_side_fw', itd.

groupDirs = dir(rootDir);

parfor i = 1:numel(groupDirs)
    if ~groupDirs(i).isdir || startsWith(groupDirs(i).name, '.')
        continue;
    end
    groupName = groupDirs(i).name;

    % Filtr grup
    if ~isempty(groupFilter) && ~contains(groupName, groupFilter)
        continue;
    end

    groupPath = fullfile(rootDir, groupName);

    % Szukanie measurement_*
    measurementDirs = dir(fullfile(groupPath, 'measurement_*'));

    for j = 1:numel(measurementDirs)

        if ~measurementDirs(j).isdir
            continue;
        end

        measurementPath = fullfile( ...
            measurementDirs(j).folder, ...
            measurementDirs(j).name);

        fprintf('Przetwarzam %s\n', measurementPath);

        tokens = strsplit(groupName,'_');


        % try
        %     doRD(measurementPath);
        % catch ME
        %     warning('Failed RD: %s\n%s', measurementPath, ME.message);
        % end
        % try
        %     doRA(measurementPath);
        % catch ME
        %     warning('Failed RA: %s\n%s', measurementPath, ME.message);
        % end

    end
end


function doRA(data_src)
dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);
srcParts = split(data_src, "\");
dataName = join(srcParts(end-1:end), "-");
clear srcParts

isEndRecording = contains(dataName, "hall-end");

rangeLimits = [0, 9]; % m

numFrames = min([dr.NumDataCubes, 1200]);
angGrid = iwr.mvdrEstimator.ScanAngles;

rngWin = hamming(iwr.config.SamplesPerChirp);

rngGrid = (0:iwr.config.SamplesPerChirp - 1) * iwr.config.RangeResolution;
[rngIdxs, rngGrid] = getLimitedIndexRangesFromDataRanges(rngGrid, rangeLimits);
rangeBins = numel(rngGrid);

radarAngle = -17;

if isEndRecording
    corDim = [4 9];
    wMask = corridorMap(angGrid, rngGrid, corDim, [0.5 1 90 + radarAngle]);
else
    wallDistance = 2.7; % m
    wMask = wallMask(wallDistance,rngGrid,angGrid);
end

% CFAR
% [rangeDim angleDim]
guardCells = [4 4];
trainCells = [4 6];
fap = 6;
method = "GOCA";

cfar = CFAR(guardCells,trainCells,fap,method,wMask);

tracker = radarTracker( ...
    FilterInitializationFcn=@initcvkf, ...
    ConfirmationThreshold=[7 10], ...
    AssignmentThreshold=[2 3],...
    DeletionThreshold=10, ...
    MaxNumTracks=5 ...
    );

warning('off','shared_tracking:internal:GNNTracker:MaxNumTracksReached');

timesDesc = ["Tworzenie mapy", "CFAR", "Filtracja detekcji", "Śledzenie"];
times = zeros(numel(timesDesc),numFrames);
detStat = zeros(3,numFrames);

tracker({objectDetection(0,[0 0])}, 0);
trackLog = cell(numFrames,1);
targetsLog = cell(numFrames,1);

for frN=1:numFrames
    srcCube = dr.read(1, frN);
    tic;
    srcCube = iwr.arrangeVirtualDataAngleULA(srcCube);
    cube = fft(srcCube.*rngWin, [], 1) / size(srcCube, 1); % fast time FFT
    cube = cube(rngIdxs, :, :); % cut cube to rangeLimits
    cube = cube - mean(cube,3); % static clutter removal

    angSize = [size(cube, 1), numel(iwr.mvdrEstimator.ScanAngles)];
    angOut = zeros(angSize);
    for i = 1:angSize(1)
        angOut(i, :) = iwr.mvdrEstimator(squeeze(cube(i, :, :))').^2;
    end
    RAM = angOut;
    times(1,frN) = toc;
    tic;
    [dets,~] = cfar.runCFAR2D(RAM);
    times(2,frN) = toc;
    detStat(1,frN) = size(dets,2);

    tic
    detStat(2,frN) = size(dets,2);
    vals=RAM(sum((dets-[0;1]).*[1;rangeBins],1)); % calculate absolute index from [xIdx;yIdx]
    [X, Y] = pol2cart(deg2rad(angGrid(dets(2, :)))+pi/2, rngGrid(dets(1, :)));
    hold off
    targets = doDbscan([X;Y;vals], 0.75, 3);
    times(3,frN) = toc;
    detStat(3,frN) = size(targets,2);

    tic
    numDets = size(targets,2);
    trackDets = cell(1,numDets);
    time = frN*iwr.config.FramePeriodicity*1e-3;
    for k=1:numDets
        trackDets{k} = objectDetection(time, targets(1:2,k));
    end
    tracks= tracker(trackDets, time);
    times(4,frN) = toc;
    trackLog{frN} = tracks';
    targetsLog{frN} = targets([1 2 end],:);
end
stat=nextname(data_src,"RA_stats_<01>.mat")
save(data_src+"\"+stat, "times","detStat", '-mat');
stat=nextname(data_src,"RA_tracking_<01>.mat")
save(data_src+"\"+stat, "trackLog","targetsLog", '-mat');
end

function doRD(data_src)
dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);
srcParts = split(data_src, "\");
dataName = join(srcParts(end-1:end), "-");
clear srcParts

isEndRecording = contains(dataName, "hall-end");

rangeLimits = [0.5, 9]; % m

numFrames = min([dr.NumDataCubes, 2e3]);
angGrid = iwr.mvdrEstimator.ScanAngles;

rngWin = hamming(iwr.config.SamplesPerChirp);
dopWin = hamming(iwr.config.NumChirps/sum(iwr.config.ActiveTransmitters))';

rngGrid = (0:iwr.config.SamplesPerChirp - 1) * iwr.config.RangeResolution;
[rngIdxs, rngGrid] = getLimitedIndexRangesFromDataRanges(rngGrid, rangeLimits);

rangeBins = numel(rngGrid);
angleBins = numel(angGrid);
dopBins = numel(dopWin);
dopGrid = (-dopBins/2:dopBins/2-1)*iwr.config.RangeRateResolution;

radarAngle = -17;

if isEndRecording
    corDim = [4 9];
    wMask = corridorMap(angGrid, rngGrid, corDim, [0.5 1 90 + radarAngle]);
    wallCutoff = rngGrid(sum(wMask,1));
else
    wallDistance = 2.7; % m
    wallCutoff = wallDistance./cosd(angGrid);
end
wMask=ones(rangeBins,dopBins,"logical");

% CFAR
% [rangeDim dopplerDim]
guardCells = [5 4];
trainCells = [3 6];
fap = 9;
method = "GOCA";

cfar = CFAR(guardCells,trainCells,fap,method,wMask);

tracker = radarTracker( ...
    FilterInitializationFcn=@initcvekf, ...
    ConfirmationThreshold=[6 10], ...
    AssignmentThreshold=[10 30],...
    DeletionThreshold=8, ...
    MaxNumTracks=5 ...
    );

warning('off','shared_tracking:internal:GNNTracker:MaxNumTracksReached');

mp = struct(Frame="Spherical", ...
    OriginPosition = zeros(1,3), ...
    OriginVelocity = zeros(1,3), ...
    Orientation=rotz(-90), ...
    HasAzimuth = true,...
    HasElevation = false,...
    HasRange = true,...
    HasVelocity = true,...
    IsParentToChild = true);

tracker({objectDetection(0,[0 1 0],"MeasurementParameters",mp)}, 0);
trackLog = cell(numFrames,1);
targetsLog = cell(numFrames,1);

timesDesc = ["Tworzenie mapy", "CFAR", "Filtracja detekcji", "Śledzenie"];
times = zeros(numel(timesDesc),numFrames);
detStat = zeros(3,numFrames);

for frN=1:numFrames
    srcCube = dr.read(1, frN);
    tic;
    srcCube = iwr.arrangeVirtualDataAngleULA(srcCube);
    cube = fft(srcCube.*rngWin, [], 1); % fast time FFT
    cube = cube(rngIdxs, :, :); % cut cube to rangeLimits
    cube = cube - mean(cube,3); % static clutter removal
    cube = fftshift(fft(cube.*reshape(dopWin, 1, 1, []),[],3),3); % slow time (Doppler) FFT
    
    RDM = squeeze(sum(abs(cube),2));
    times(1,frN) = toc;
    tic;
    [dets,~] = cfar.runCFAR2D(RDM);
    times(2,frN) = toc;
    detStat(1,frN) = size(dets,2);
    targets = zeros(6,size(dets,2));

    tic
    for detNr=1:size(dets,2)
        det = dets(:,detNr);
        angSpectrum = iwr.mvdrEstimator(squeeze(cube(det(1),:,det(2)-4:det(2)+4))');
        [~,idx] = max(angSpectrum);
        rng=rngGrid(det(1));
        if rng >= wallCutoff(idx)
            continue % leave the column zeroed
        end
        ang=iwr.mvdrEstimator.ScanAngles(idx);
        [x, y] = pol2cart(deg2rad(ang+90), rng);
        targets(:,detNr)= [x y ang rng dopGrid(det(2)) RDM(det(1),det(2))];
    end

    targets = targets(:, targets(end,:)>0);
    detStat(2,frN) = size(dets,2);

    targets = doDbscan(targets, 0.5, 3);
    times(3,frN) = toc;
    detStat(3,frN) = size(targets,2);

    tic
    numDets = size(targets,2);
    trackDets = cell(1,numDets);
    time = frN*iwr.config.FramePeriodicity*1e-3;
    for k=1:numDets
        trackDets{k} = objectDetection(time, targets(3:5,k),MeasurementParameters=mp);
    end
    tracks= tracker(trackDets, time);
    times(4,frN) = toc;
    trackLog{frN} = tracks';
    targetsLog{frN} = targets([1 2 6],:);
end
stat=nextname(data_src,"RD_stats_<01>.mat")
save(data_src+"\"+stat, "times","detStat", '-mat');
stat=nextname(data_src,"RD_tracking_<01>.mat")
save(data_src+"\"+stat, "trackLog","targetsLog", '-mat');
end

function mask = wallMask(wallDistance,rngGrid,angGrid)
wallCutoff = wallDistance./cosd(angGrid);
[A,B]= meshgrid(wallCutoff,rngGrid);
mask=A>B;
end

function detections = doDbscan(targets,epsilon,minpts)
if isempty(targets)
    detections=targets;
    return
end
clust = dbscan(targets(1:2,:)',epsilon,minpts);
ids = unique(clust);
ids=ids(ids>0);
detections = zeros(size(targets,1),numel(ids));
for i=1:numel(ids)
    part = targets(:,clust==ids(i));
    detections(:,i)=mean(part,2);
    % ,"Weights",part(end,:)
end
end