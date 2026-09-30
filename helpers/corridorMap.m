
function mask = corridorMap(angles, ranges, corDim, radarPos)
% angles: vector of angles analyzed by the radar
% ranges: vector of ranges analyzed by the radar
% corDim: [xLength yLength]
% radarPos: [x, y, angle] relative to corridor left bottom corner (0,0)
    corX = [0 corDim(1) corDim(1) 0];
    corY = [0 0 corDim(2) corDim(2)];
    
    [A, R] = meshgrid(angles, ranges);
    [X,Y] = pol2cart(deg2rad(A + radarPos(3)), R);

    mask = inpolygon(X+radarPos(1), Y+radarPos(2), corX, corY);
