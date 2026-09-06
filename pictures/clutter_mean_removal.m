addpath("helpers")
data_src="C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_fw_0\measurement_002";

dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);

rangeLimits = [0.5, 9]; % m
angFftLength = 64;

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

angFftGrid=asind((0:angFftLength-1)*2/angFftLength-1);

cube = iwr.arrangeVirtualDataAngleULA(dr.read(1,215));

cube = fft(cube.*rngWin, [], 1); % fast time FFT
cube = cube(rngIdxs, :, :); % cut cube to rangeLimits

cubeClut = cube;
cube = cube - mean(cube,3); % static clutter removal

angSize = [size(cube, 1), numel(iwr.mvdrEstimator.ScanAngles)];
angOut = zeros(angSize);
angOutClut = zeros(angSize);

for i = 1:angSize(1)
    angOut(i, :) = iwr.mvdrEstimator(squeeze(cube(i, :, :))');
    angOutClut(i, :) = iwr.mvdrEstimator(squeeze(cubeClut(i, :, :))');
end

% slow time (Doppler) FFT
cube = fftshift(fft(cube.*reshape(dopWin, 1, 1, []),[],3),3);
cubeClut = fftshift(fft(cubeClut.*reshape(dopWin, 1, 1, []),[],3),3);

dopOut=squeeze(sum(abs(cube),2));
dopOutClut=squeeze(sum(abs(cubeClut),2));
figure;
t = tiledlayout(2,2,'TileSpacing','Compact','Padding','compact');
nexttile
plotWithRadar(dopGrid, rngGrid, dopOut)
ylabel("Mapa RD","FontWeight","bold");
title("Z filtracją")
nexttile
plotWithRadar(dopGrid, rngGrid, dopOutClut);
title("Bez filtracji")

nexttile
plotWithRadar(angGrid, rngGrid, angOut);
ylabel("Mapa RA","FontWeight","bold");
nexttile
plotWithRadar(angGrid, rngGrid, angOutClut);

function plotWithRadar(X,Y,Z)
hold on
imagesc(X,Y,Z);
xlim([X(1) X(end)])
ylim([0 Y(end)])
plot(0,0,"v",'Color','red')
pbaspect([1 1 1]);
hold off
end