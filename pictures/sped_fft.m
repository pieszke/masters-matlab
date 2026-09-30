figure()

t = tiledlayout(1,3,"TileSpacing","compact","Padding","tight");

load("C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_run_0\measurement_002\RA_tracking_01.mat")
showSpeedAndFFT(trackLog,nexttile(t,3))%,nexttile(t,4))
title("Bieg")

load("C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_fw_0\measurement_002\RA_tracking_01.mat")
showSpeedAndFFT(trackLog,nexttile(t,2))%,nexttile(t,5))
title("Szybki marsz")

load("C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_sw_0\measurement_002\RA_tracking_01.mat")
showSpeedAndFFT(trackLog,nexttile(t,1))%,nexttile(t,6))
title("Marsz")

ax = findobj(t.Children,'Type','Axes');

xlimAll = vertcat(ax.XLim);
ylimAll = vertcat(ax.YLim);

xLim = [min(xlimAll(:,1)) max(xlimAll(:,2))];
yLim = [min(ylimAll(:,1)) max(ylimAll(:,2))];

set(ax,'XLim',xLim,'YLim',yLim);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function showSpeedAndFFT(trackLog,ax1)%,ax2)

trackLogArr = [trackLog{:}];
trackLogArr = [trackLogArr(:).State; ...
    trackLogArr(:).UpdateTime; ...
    double([trackLogArr(:).TrackID])];

ids = unique(trackLogArr(end,:));

hold(ax1,"on")

% wspólna siatka częstotliwości
fGrid = linspace(0,5,500);
fftSum = zeros(size(fGrid));
nTracksUsed = 0;

for n = 1:numel(ids)

    id = ids(n);
    part = trackLogArr(:,trackLogArr(end,:)==id);

    if size(part,2) < 20
        continue
    end

    time = part(end-1,:);
    speed = hypot(part(2,:),part(4,:));

    %% usunięcie duplikatów czasu

    [timeUnique,idx] = unique(time,'stable');
    speedUnique = speed(idx);

    if numel(timeUnique) < 10
        continue
    end

    %% wykres prędkości

    plot(ax1,timeUnique,speedUnique)

    %% przygotowanie danych do FFT

    dt = median(diff(timeUnique));

    if ~isfinite(dt) || dt <= 0
        continue
    end

    Fs = 1/dt;

    tUniform = timeUnique(1):dt:timeUnique(end);

    % luki pozostają zerami
    speedUniform = zeros(size(tUniform));

    sampleIdx = round((timeUnique - tUniform(1))/dt) + 1;
    speedUniform(sampleIdx) = speedUnique;

    %% FFT

    x = speedUniform - mean(speedUniform);

    N = numel(x);

    Y = fft(x);

    f = Fs*(0:floor(N/2))/N;

    A = abs(Y(1:floor(N/2)+1))/N;
    A(2:end-1) = 2*A(2:end-1);

    %% akumulacja widm

    fftSum = fftSum + interp1( ...
        f, ...
        A, ...
        fGrid, ...
        'linear', ...
        0);

    nTracksUsed = nTracksUsed + 1;

end

xlabel(ax1,"Czas [s]")
ylabel(ax1,"Prędkość [m/s]")
grid(ax1,"on")
return
%% rysowanie sumarycznego FFT

if nTracksUsed > 0
    fftMean = fftSum / nTracksUsed;
    [peakVal,peakIdxLocal] = max(fftMean);

    peakFreq = fGrid(peakIdxLocal);

    plot(ax2,fGrid,fftMean,...
        'k','LineWidth',2);
    hold(ax2,"on")

    plot(ax2,...
        peakFreq,...
        peakVal,...
        'ro',...
        'MarkerSize',8,...
        'LineWidth',2);

    text(ax2,...
        peakFreq,...
        peakVal,...
        sprintf(' %.2f Hz',peakFreq),...
        'FontWeight','bold',...
        'VerticalAlignment','bottom');
end


xlabel(ax2,"Częstotliwość [Hz]")
ylabel(ax2,"Suma amplitud FFT")
grid(ax2,"on")

xlim(ax2,[0 5])

end
% function showSpeedAndFFT(trackLog,ax1,ax2)
% 
% trackLogArr = [trackLog{:}];
% trackLogArr = [trackLogArr(:).State; ...
%                trackLogArr(:).UpdateTime; ...
%                double([trackLogArr(:).TrackID])];
% 
% 
% hold(ax1,"on")
% hold(ax2,"on")
% 
% %% Collect all speed samples
% 
% timeAll = trackLogArr(end-1,:);
% speedAll = hypot(trackLogArr(2,:),trackLogArr(4,:));
% 
% %% Remove duplicate timestamps
% % Average speeds that correspond to the same UpdateTime
% 
% [timeUnique,~,groupIdx] = unique(timeAll);
% 
% speedUnique = accumarray( ...
%     groupIdx(:), ...
%     speedAll(:), ...
%     [], ...
%     @mean);
% 
% dt = 0.04;
% Fs = 1/dt;
% 
% %% Uniform time vector spanning whole recording
% 
% tUniform = timeUnique(1):dt:timeUnique(end);
% 
% %% Fill gaps with zeros
% 
% speedUniform = interp1( ...
%     timeUnique,...
%     speedUnique,...
%     tUniform,...
%     'linear',0);
% 
% %% Time-domain plot
% 
% plot(ax1,tUniform,speedUniform,'LineWidth',1.5)
% xlabel(ax1,'Czas [s]')
% ylabel(ax1,'Prędkość [m/s]')
% 
% %% FFT
% 
% x = speedUniform;% - mean(speedUniform)
% 
% N = numel(x);
% 
% Y = fft(x);
% 
% P2 = abs(Y/N);
% P1 = P2(1:floor(N/2)+1);
% P1(2:end-1) = 2*P1(2:end-1);
% 
% f = Fs*(0:floor(N/2))/N;
% 
% plot(ax2,f,P1,'LineWidth',1.5)
% 
% xlim(ax2,[0 10])
% 
% xlabel(ax2,'Częstotliwość [Hz]')
% ylabel(ax2,'Amplituda')
% grid(ax2,'on')
% 
% xlim(ax2,[0 5]) % zwykle interesujący zakres dla chodu
% 
% end
