addpath("helpers")

data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_test_0\45to-45deg";
data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_run_0\measurement_001";
% data_src="C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_sw_6\measurement_001";
data_src="C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_sw_3\measurement_001";
dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);
srcParts = split(data_src, "\");
dataName = join(srcParts(end-1:end), "-");
clear srcParts

rangeLimits = [0.5, 8]; % m
angFftLength = 180;

numFrames = min([dr.NumDataCubes, 900]);
angGrid = asind((0:angFftLength-1)*2/angFftLength-1);

rngWin = hann(iwr.config.SamplesPerChirp);
dopWin = hann(iwr.config.NumChirps/sum(iwr.config.ActiveTransmitters))';

rngGrid = (0:iwr.config.SamplesPerChirp - 1) * iwr.config.RangeResolution;
[rngIdxs, rngGrid] = getLimitedIndexRangesFromDataRanges(rngGrid, rangeLimits);

DATA = zeros(numel(rngIdxs), numel(angGrid), numFrames);

for frN = 1:numFrames
    srcCube = dr.read(1, frN);
    srcCube = iwr.arrangeVirtualDataAngleULA(srcCube);
    cube = fft(srcCube.*rngWin, [], 1) / size(srcCube, 1); % fast time FFT
    cube = cube(rngIdxs, :, :); % cut cube to rangeLimits
    cube = cube - mean(cube,3); % static clutter removal
    
    DATA(:, :, frN) = sum(abs(fftshift(fft(cube,angFftLength,2),2)),3);
end

save(data_src+"\RA_FFT.mat", "DATA", "rngGrid", "angGrid", '-mat');
filename = data_src + "\RA_FFT.gif";
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