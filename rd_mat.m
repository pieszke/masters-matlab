addpath("helpers")

data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_test_0\45to-45deg";
data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_run_0\measurement_001";
data_src="C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_sw_3\measurement_001";

dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);
srcParts = split(data_src, "\");
dataName = join(srcParts(end-1:end), "-");
clear srcParts

rangeLimits = [0.5, 7]; % m
numFrames = min([dr.NumDataCubes, 900]);

cube = iwr.arrangeVirtualDataAngleULA(dr.read(1, 1));
[nRange, nRx, nChirps] = size(cube);


rngWin = hamming(nRange);
dopWin = hamming(nChirps);

% (0:conf.SamplesPerChirp-1)*conf.ADCSampleRate*1e6/conf.SamplesPerChirp*c/2/(conf.SweepSlope*1e12)
rngGrid = (0:iwr.config.SamplesPerChirp - 1) * iwr.config.RangeResolution;
[rngIdxs, rngGrid] = getLimitedIndexRangesFromDataRanges(rngGrid, rangeLimits);
dopGrid = (-nChirps/2:nChirps/2-1)*iwr.config.RangeRateResolution;

DATA = zeros(numel(rngGrid), nChirps,  numFrames);

for frN = 1:numFrames
    cube = dr.read(1, frN);
    cube = iwr.arrangeVirtualDataAngleULA(cube);

    cube = fft(cube.*rngWin, [], 1); % fast time FFT
    cube = cube(rngIdxs, :, :); % cut cube to rangeLimits
    % cube = cube - mean(cube,3); % static clutter removal
    cube = fftshift(fft(cube.*reshape(dopWin, 1, 1, []),[],3),3); % slow time (Doppler) FFT

    DATA(:, :, frN) = squeeze(sum(abs(cube),2));
end

save(data_src+"\RD.mat", "DATA", "rngGrid", "dopGrid", '-mat');
filename = data_src + "\RD.gif";
delay = iwr.config.FramePeriodicity * 1e-3;
for i = 1:numFrames
    data = DATA(:, :, i);
    % show3D(rngGrid,dopGrid,data')
    % drawnow limitrate
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