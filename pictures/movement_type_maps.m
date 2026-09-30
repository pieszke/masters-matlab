addpath("helpers")
data_dir = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\";

datas = {
    {data_dir + "hall-along_side_sw_3\measurement_001", 210, 'Marsz'},
    {data_dir + "hall-along_side_fw_3\measurement_001", 250,'Szybki marsz'},
    {data_dir + "hall-along_side_run_3\measurement_001", 200, "Bieg"}
    };

datas = {
    {data_dir + "hall-along_side_sw_5\measurement_001", 220, 'Marsz'},
    {data_dir + "hall-along_side_fw_5\measurement_001", 230,'Szybki marsz'},
    {data_dir + "hall-along_side_run_5\measurement_001", 275, "Bieg"}
    };


figure(2);
clf
nData=numel(datas);
t = tiledlayout(nData,2,'TileSpacing','Compact','Padding','compact');

for n =1:nData
    A = nexttile();
    D = nexttile();
    plotOnAxes(datas{n}{1:2},A,D)
end
title(t.Children(5),"Mapy RD")
title(t.Children(6),"Mapy RA")
pos = [t.Position(1)/3 0 0.3 t.Position(1)/3].*[1;1;1];
pos(:,2) = (nData-(1:nData))/nData;
for n=1:nData
    annotation('textbox',pos(n,:),String=datas{n}{end}, Rotation=90, HorizontalAlignment="center",VerticalAlignment="middle",FontWeight="bold",EdgeColor='w',FontSize=12);
end



function plotOnAxes(data_src,frameNumber, axRA, axRD)
dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);

rangeLimits = [0, 9]; % m
angGrid = iwr.mvdrEstimator.ScanAngles;

rngWin = hamming(iwr.config.SamplesPerChirp);
dopWin = hamming(iwr.config.NumChirps/sum(iwr.config.ActiveTransmitters))';

rngGrid = (0:iwr.config.SamplesPerChirp - 1) * iwr.config.RangeResolution;
[rngIdxs, rngGrid] = getLimitedIndexRangesFromDataRanges(rngGrid, rangeLimits);

dopBins = numel(dopWin);
dopGrid = (-dopBins/2:dopBins/2-1)*iwr.config.RangeRateResolution;


cube = iwr.arrangeVirtualDataAngleULA(dr.read(1,frameNumber));

cube = fft(cube.*rngWin, [], 1); % fast time FFT
cube = cube(rngIdxs, :, :); % cut cube to rangeLimits

cube = cube - mean(cube,3); % static clutter removal

angSize = [size(cube, 1), numel(iwr.mvdrEstimator.ScanAngles)];
angOut = zeros(angSize);

for i = 1:angSize(1)
    angOut(i, :) = iwr.mvdrEstimator(squeeze(cube(i, :, :))').^2;
end

cube = fftshift(fft(cube.*reshape(dopWin, 1, 1, []),[],3),3);

dopOut=squeeze(sum(abs(cube),2));

imagesc(axRA,angGrid, rngGrid, angOut);
xlabel(axRA,"Kąt [°]")
ylabel(axRA,"Dystans [m]")

imagesc(axRD, dopGrid, rngGrid, dopOut);
xlabel(axRD,"Prędkość radialna [m/s]")
ylabel(axRD,"Dystans [m]")

end
