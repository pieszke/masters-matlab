figure()

t = tiledlayout(1,3,"TileSpacing","compact","Padding","tight");

nexttile
load("C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_sw_0\measurement_002\RA_tracking_01.mat")
showTrackAndSpeed(trackLog)
title("Marsz")

nexttile
load("C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_fw_0\measurement_002\RA_tracking_01.mat")
showTrackAndSpeed(trackLog)
title("Szybki marsz")

nexttile
load("C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST\hall-end_side_run_0\measurement_002\RA_tracking_01.mat")
showTrackAndSpeed(trackLog)
title("Bieg")

cb = colorbar;
clim([0 3])
cb.Label.String = 'Prędkość [m/s]';

ax = findobj(t.Children,'Type','Axes');

xlimAll = vertcat(ax.XLim);
ylimAll = vertcat(ax.YLim);

xLim = [min(xlimAll(:,1)) max(xlimAll(:,2))];
yLim = [min(ylimAll(:,1)) max(ylimAll(:,2))];

set(ax,'XLim',xLim,'YLim',yLim);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function showTrackAndSpeed(trackLog)
gndTruth = [3 3 6 6 3; 0 23 23 6 6]*0.305;
plot(gndTruth(1,:),gndTruth(2,:),":","Color","#aaaaaa","LineWidth",2);

radarAngle = -17;
rotMat = rotz(radarAngle);
rotMat = rotMat(1:2,1:2);

trackLogArr = [trackLog{:}];
trackLogArr = [trackLogArr(:).State; trackLogArr(:).UpdateTime; double([trackLogArr(:).TrackID])];
ids = unique(trackLogArr(end,:));
for n=1:numel(ids)
    id=ids(n);
    part = trackLogArr(:,trackLogArr(end,:)==id);
    XY = rotMat*part([1 3],:);
    speed = hypot(part(2,:),part(4,:));

    surface( ...
        [XY(1,:); XY(1,:)], ...
        [XY(2,:); XY(2,:)], ...
        zeros(2,size(XY,2)), ...
        [speed; speed], ...
        'FaceColor','none', ...
        'EdgeColor','interp', ...
        'LineWidth',3);
end
xlabel("Dystans [m]")
ylabel("Dystans [m]")
hold on
plot(0,0,"v",'Color','r','LineWidth',1)
axis equal fill;
hold off
colormap(turbo)
clim([0 3])
end