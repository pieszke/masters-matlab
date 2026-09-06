addpath("helpers")
data_src="C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_fw_0\measurement_002";

iwr = IWR1843(data_src);
load(data_src+"\RA.mat", "-mat");
[rangeBins, angleBins, numFrames] = size(DATA);

rangeLimits = [0.5, 9]; % m
bgFilterFrameCount = 100;
bgCoeff = 0.98;
showFrame = 195;

for frN = max([showFrame-BG.length 1]):showFrame-1
    BG.addSample(abs(DATA(:, :, frN)));
end
raw = abs(DATA(:, :, showFrame));
data = BG.addSampleNoBg(raw, bgCoeff);
flt = data;
flt(flt<0)=0;

figure;
t = tiledlayout(2,2,'TileSpacing','Compact','Padding','compact');

nexttile
plotWithRadar(angGrid, rngGrid, raw,"Sygnał z ramki")

nexttile
plotWithRadar(angGrid, rngGrid, BG.value,"Tło");

nexttile
plotWithRadar(angGrid, rngGrid, data, "Sygnał bez tła");

nexttile
plotWithRadar(angGrid, rngGrid, flt,"Po odcięciu ujemnych wartości");

function plotWithRadar(X,Y,Z,titleText)
hold on
imagesc(X,Y,Z);
% view([-30, 10])
% shading interp
title(titleText)
xlim(sort([X(1) X(end)]))
ylim([0 Y(end)])
colorbar
% plot(0,0,"v",'Color','red')
% pbaspect([1 1 1]);
hold off
end