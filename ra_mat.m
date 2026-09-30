addpath("helpers")

data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_test_0\45to-45deg";
data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_run_0\measurement_001";
% data_src="C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_sw_6\measurement_001";
data_src="C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_fw_0\measurement_003";
dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);
srcParts = split(data_src, "\");
dataName = join(srcParts(end-1:end), "-");
clear srcParts

rangeLimits = [0.5, 8]; % m
numFrames = min([dr.NumDataCubes, 900]);
angGrid = iwr.mvdrEstimator.ScanAngles;

rngWin = hann(iwr.config.SamplesPerChirp);
dopWin = hann(iwr.config.NumChirps/sum(iwr.config.ActiveTransmitters))';

rngGrid = (0:iwr.config.SamplesPerChirp - 1) * iwr.config.RangeResolution;
[rngIdxs, rngGrid] = getLimitedIndexRangesFromDataRanges(rngGrid, rangeLimits);

DATA = zeros(numel(rngIdxs), numel(iwr.mvdrEstimator.ScanAngles), numFrames);

for frN = 1:numFrames
    srcCube = dr.read(1, frN);
    srcCube = iwr.arrangeVirtualDataAngleULA(srcCube);
    cube = fft(srcCube.*rngWin, [], 1) / size(srcCube, 1); % fast time FFT
    cube = cube(rngIdxs, :, :); % cut cube to rangeLimits
    cube = cube - mean(cube,3); % static clutter removal
    
    angSize = [size(cube, 1), numel(iwr.mvdrEstimator.ScanAngles)];
    angOut = zeros(angSize);
    for i = 1:angSize(1)
        angOut(i, :) = iwr.mvdrEstimator(squeeze(cube(i, :, :))').^2;
    end
    DATA(:, :, frN) = angOut;
end

save(data_src+"\RA.mat", "DATA", "rngGrid", "angGrid", '-mat');
filename = data_src + "\RA.gif";
delay = iwr.config.FramePeriodicity * 1e-3;
for i = 1:numFrames
    data = DATA(:, :, i);
    data = rescale(data, 1, 256);
    if i == 1
        imwrite(data, parula, filename, "gif", LoopCount = Inf, ...
            DelayTime = delay)
    else
        imwrite(data, parula, filename, "gif", WriteMode = "append", ...
            DelayTime = delay)
    end
end

clear