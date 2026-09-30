rootDir = 'C:\Users\kpiec\OneDrive - Politechnika Łódzka\Studia\2Sem3\magisterka\pomiary\IWR1843BOOST';
db = buildTrackingDatabase(rootDir);

%% CONFIG

minTrackLen = 10;

activities = {
    {"none" ,[0 0.95],"Brak ruchu"}
    {"sw" ,[0.95 1.4],"Marsz"}
    {"fw" ,[1.4 2.1],"Szybki marsz"}
    {"run",[2.1 5.0],"Bieg"}
};

mapTypes = {'RA','RD'};
places = {'hall-end','hall-along'};
gaits = {'sw','fw','run','none'};


%% INITIALIZE STATISTICS

for m = 1:numel(mapTypes)
    mapType = mapTypes{m};

    for p = 1:numel(places)
        place = places{p};

        for g = 1:numel(gaits)
            gait = gaits{g};

            stats.(mapType).(matlab.lang.makeValidName(place)).(gait) = struct( ...
                'acceptedTracks',0,...
                'rejectedTracks',0,...
                'samples',zeros(1,numel(activities)));
        end
    end
end


%% MAIN LOOP
processed=0;
for k = 1:numel(db)
    if ~(ismember(db(k).place,places) && ismember(db(k).gait,gaits))
        continue
    end
    if str2num(db(k).person)>5
        continue
    end
    expectedGait = db(k).gait;
    place = matlab.lang.makeValidName(db(k).place);

    for mapIdx = 1:2

        if mapIdx == 1
            file = db(k).RAfile;
            mapType = 'RA';
        else
            file = db(k).RDfile;
            mapType = 'RD';
        end

        if isempty(file) || ~isfile(file)
            continue;
        end

        S = load(file,'trackLog');

        trackLog = S.trackLog;

        if isempty(trackLog)
            continue;
        end

        processed = processed+1;

        %% convert to array

        trackLogArr = [trackLog{:}];
        if isempty(trackLogArr)
            continue
        end

        trackLogArr = [ ...
            trackLogArr(:).State ; ...
            double([trackLogArr(:).TrackID]) ...
            ];
        

        trackIDs = unique(trackLogArr(end,:));

        for id = trackIDs

            mask = trackLogArr(end,:)==id;
            part = trackLogArr(:,mask);

            N = size(part,2);

            %% reject short tracks

            if N <= minTrackLen

                stats.(mapType).(place).(expectedGait).rejectedTracks = ...
                    stats.(mapType).(place).(expectedGait).rejectedTracks + 1;

                continue;
            end

            stats.(mapType).(place).(expectedGait).acceptedTracks = ...
                stats.(mapType).(place).(expectedGait).acceptedTracks + 1;

            %% speed

            speed = hypot(part(2,:),part(4,:));

            %% classify every sample

            for a = 1:numel(activities)

                lims = activities{a}{2};

                stats.(mapType).(place).(expectedGait).samples(a) = ...
                    stats.(mapType).(place).(expectedGait).samples(a) + ...
                    sum(speed >= lims(1) & speed < lims(2));

            end
        end
    end

end

gaits = {['sw',"Marsz"],['fw',"Szybki marsz"],['run',"Bieg"],['none',"Brak ruchu"]};
places = {['hall-end',"scenariusz B"],['hall-along',"scenariusz A"]};
mapTypes = {'RA','RD'};

figure('Color','w');

tiledlayout(numel(mapTypes),numel(places), ...
    'TileSpacing','compact','Padding','compact');

for m = 1:numel(mapTypes)

    mapType = mapTypes{m};

    for p = 1:numel(places)

        placeField = matlab.lang.makeValidName(places{p}(1));

        CM = zeros(numel(gaits)-1,numel(gaits));

        for gt = 1:(numel(gaits)-1)

            s = stats.(mapType).(placeField).(gaits{gt}(1)).samples;

            if sum(s) > 0
                CM(gt,:) = s ./ sum(s);
            end

        end

        nexttile

        imagesc(100*CM);
        axis image

        colormap(parula)
        colorbar

        clim([0 100]);

        xticks(1:numel(gaits));
        yticks(1:numel(gaits));

        xticklabels(cellfun(@(g) g(2),gaits));
        yticklabels(cellfun(@(g) g(2),gaits));

        xlabel('Wyznaczone');
        ylabel('Oczekiwane');

        title(sprintf('%s | %s',mapType,places{p}(2)));

        for r = 1:size(CM,1)
            for c = 1:size(CM,2)

                text(c,r,...
                    sprintf('%.1f%%',100*CM(r,c)),...
                    'HorizontalAlignment','center',...
                    'Color','w',...
                    'FontWeight','bold');

            end
        end

    end
end

figure('Color','w');

t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for m = 1:numel(mapTypes)

    nexttile

    missRate = zeros(numel(places),numel(gaits)-1);

    for p = 1:numel(places)

        placeField = matlab.lang.makeValidName(places{p}(1));

        for g = 1:(numel(gaits)-1)

            st = stats.(mapTypes{m}).(placeField).(gaits{g}(1));

            totalTracks = ...
                st.acceptedTracks + ...
                st.rejectedTracks;

            if totalTracks > 0
                missRate(p,g) = ...
                    st.rejectedTracks / totalTracks;
            end

        end
    end

    bh = bar(100*missRate);

    ylabel('Odrzucone ścieżki [%]');

    xticklabels(cellfun(@(g) g(2),places));

    title(mapTypes{m});

    grid on
end

leg = legend(cellfun(@(g) g(2),gaits(1:end-1)));
leg.Layout.Tile = 'north';
leg.Orientation = 'horizontal';



function result = queryTrackingDatabase(db,varargin)

result = db;

for k = 1:2:numel(varargin)

    field = varargin{k};
    value = varargin{k+1};

    mask = strcmp({result.(field)},value);
    result = result(mask);

end

end