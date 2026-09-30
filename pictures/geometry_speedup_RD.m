

timesDesc = ["Tworzenie mapy", "CFAR", "Filtracja detekcji", "Śledzenie"];
series=["Brak filtracji","Filtracja po CFAR"];
series = [series+" A" series+" B"];

serNum = numel(series);
data=cell(serNum*2,1);

data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-along_side_fw_5\measurement_002";
for n=1:serNum
    data{n} = load(sprintf("%s\\RD_stats_%02d.mat",data_src, n), "times", "detStat");
    data{n}.times = cat(2,data{n}.times, data{n}.times);
    data{n}.detStat = cat(2,data{n}.detStat, data{n}.detStat);
end
data_src = "C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_sw_0\measurement_002";
for n=1:serNum
    data{n+serNum} = load(sprintf("%s\\RD_stats_%02d.mat",data_src, n), "times", "detStat");
end
timesDesc = [timesDesc "Suma"];

timesSize = size(data{5}.times);
times = zeros([serNum timesSize(1)+1, timesSize(2)*2]);
detStat = zeros([serNum size(data{1}.detStat).*[1 2]]);
for n=1:serNum
    times(n,1:end-1,:)=cat(2,data{2*n-1}.times,data{2*n}.times);
    times(n,end,:) = sum(squeeze(times(n,:,:)),1);
    detStat(n,:,:)=cat(2,data{2*n-1}.detStat,data{2*n}.detStat);
end

ts = numel(timesDesc);
figure(10)
clf
for n=1:ts
    subplot(ts,1,n)
    hold on
    for m=1:serNum
        histogram(squeeze(times(m,n,:)))
    end
    hold off
    ylabel(timesDesc(n))
    legend(series)
end
% sgtitle("Histogramy czasów realizacji części procesu RA")

figure(11)
clf


vals=[50 90 99];
prctl = prctile(squeeze(times(:,end,:)),vals,2);
subplot(1,2,1)
bar(prctl')
xticklabels(string(vals))
ylabel("Czas [s]")
subplot(1,2,2)
bar(([prctl(1:2,:)./(max(prctl(1:2,:),[],1)); prctl(3:4,:)./(max(prctl(3:4,:),[],1))])')
l=legend(series,"Orientation","horizontal");
pos=l.Position;
set(l,'Position',[(1-pos(3))/2 0.05 pos(3) pos(4)]);
xticklabels(string(vals))
ylabel("Czas względem najdłuższego")
% sgtitle("Długość trwania potoku RA w różnych centylach")



figure(12)
clf

allData = [];
xGroup = [];
seriesGroup = [];

for m = 1:serNum
    tms = squeeze(times(m,:,:));
    allData = [allData; tms(:)];

    xGroup = [xGroup; repmat((1:numel(timesDesc))', size(tms,2), 1)];

    seriesGroup = [seriesGroup; ...
        repmat(categorical(series(m)), numel(tms), 1)];
end

boxchart(xGroup, allData, 'GroupByColor', seriesGroup)

xticks(1:numel(timesDesc))
xticklabels(timesDesc)
ylabel("Czas [s]")
% title("Rozkład czasu realizacji części procesu RA")
legend(series)