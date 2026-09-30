db



function db = buildTrackingDatabase(rootDir)

db = struct();

groupDirs = dir(rootDir);
groupDirs = groupDirs([groupDirs.isdir]);

entryIdx = 0;

for i = 1:numel(groupDirs)

    groupName = groupDirs(i).name;

    if startsWith(groupName,'.')
        continue;
    end

    % Parse group name
    tokens = strsplit(groupName,'_');

    if numel(tokens) ~= 4
        warning('Skipping invalid group name: %s', groupName);
        continue;
    end

    groupPath = fullfile(rootDir,groupName);

    measurementDirs = dir(fullfile(groupPath,'measurement_*'));

    for j = 1:numel(measurementDirs)

        if ~measurementDirs(j).isdir
            continue;
        end

        measurementPath = fullfile( ...
            measurementDirs(j).folder, ...
            measurementDirs(j).name);

        % Latest RA file
        RAfiles = dir(fullfile(measurementPath,'RA_tracking_*.mat'));

        % Latest RD file
        RDfiles = dir(fullfile(measurementPath,'RD_tracking_*.mat'));

        if isempty(RAfiles) && isempty(RDfiles)
            continue;
        end

        entryIdx = entryIdx + 1;

        db(entryIdx).place      = tokens{1};
        db(entryIdx).direction  = tokens{2};
        db(entryIdx).gait       = tokens{3};
        db(entryIdx).person     = tokens{4};

        db(entryIdx).groupName      = groupName;
        db(entryIdx).measurement    = measurementDirs(j).name;
        db(entryIdx).measurementPath = measurementPath;

        db(entryIdx).RAfile = getLatestFile(RAfiles);
        db(entryIdx).RDfile = getLatestFile(RDfiles);
    end

end

end


function filepath = getLatestFile(files)

if isempty(files)
    filepath = '';
    return;
end

[~,idx] = max([files.datenum]);

filepath = fullfile( ...
    files(idx).folder, ...
    files(idx).name);

end