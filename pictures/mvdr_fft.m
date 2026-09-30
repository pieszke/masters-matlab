addpath("helpers")

data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_test_0\45to-45deg";

dr = dca1000FileReader("RecordLocation", data_src);
iwr = IWR1843(data_src);
srcParts = split(data_src, "\");
dataName = join(srcParts(end-1:end), "-");
clear srcParts

rangeLimits = [0.5, 9]; % m
frN = 46;
numFrames = min([dr.NumDataCubes, 900]);
angGrid = iwr.mvdrEstimator.ScanAngles;
angFftLength = 128;
angFftGrid=-asind((0:angFftLength-1)*freq2wavelen(iwr.config.CenterFrequency*1e9)/(iwr.lambda/2)/angFftLength-1);


rngWin = hamming(iwr.config.SamplesPerChirp);
dopWin = hamming(iwr.config.NumChirps/sum(iwr.config.ActiveTransmitters))';

rngGrid = (0:iwr.config.SamplesPerChirp - 1) * iwr.config.RangeResolution;
[rngIdxs, rngGrid] = getLimitedIndexRangesFromDataRanges(rngGrid, rangeLimits);
angleLimits=angGrid([1 end]);
[angFftIdx,angFftGrid] = getLimitedIndexRangesFromDataRanges(angFftGrid,angleLimits);

srcCube = dr.read(1, frN);
srcCube = iwr.arrangeVirtualDataAngleULA(srcCube);
cube = fft(srcCube.*rngWin, [], 1); % fast time FFT
cube = cube(rngIdxs, :, :); % cut cube to rangeLimits
cube = cube - mean(cube,3); % remove mean of all pulses in CPI

angSize = [size(cube, 1), numel(iwr.mvdrEstimator.ScanAngles)];
angOut = zeros(angSize);
for i = 1:angSize(1)
    part = squeeze(cube(i, :, :));
    angOut(i, :) = iwr.mvdrEstimator(part').^2;
end

angFFT = fftshift(fft(cube,angFftLength,2),2);
angFFT = squeeze(sum(abs(angFFT),3));

tiledlayout(2,1,"TileSpacing","tight")

nexttile
imagesc(angFftGrid,rngGrid,angFFT(:,angFftIdx));
xlabel("Kąt [°]")
ylabel("Dystans [m]")
title("Kątowe FFT")

nexttile
imagesc(iwr.mvdrEstimator.ScanAngles,rngGrid,angOut);
xlabel("Kąt [°]")
ylabel("Dystans [m]")
title("Metoda MVDR")


showDist=17;
rngGrid(showDist)
figure

tiledlayout(1,2,"TileSpacing","tight")

nexttile
plot(angFftGrid,angFFT(showDist,angFftIdx));
xlabel("Kąt [°]")
title("Kątowe FFT")

nexttile
plot(iwr.mvdrEstimator.ScanAngles,angOut(showDist,:));
xlabel("Kąt [°]")
title("Metoda MVDR")
