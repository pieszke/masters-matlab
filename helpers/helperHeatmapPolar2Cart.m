function [cartData, xBounds, yBounds] = helperHeatmapPolar2Cart(polarData,rangeLimits,thetaLimits,Nx,Ny,pad2Square,squareLen)
    rangeLimits = rangeLimits(:)';
    thetaLimits = thetaLimits(:)';
    thetaLimits = 90 - thetaLimits;

    if diff(thetaLimits) == 0
        thetaLimits = thetaLimits + [-1 1];
    end
    [nRange,nTheta] = size(polarData); % input size
    inputRangeBins = linspace(rangeLimits(1),rangeLimits(2),nRange);
    inputAngleBins = linspace(thetaLimits(1),thetaLimits(2),nTheta);
    
    % Each Cartesian coordinate and val from input data (no interpolation)
    xar = zeros(nRange*nTheta, 1);
    yar = zeros(nRange*nTheta, 1);
    var = zeros(nRange*nTheta, 1);
    
    % Get Cartesian bounds
    cornerXCoordinates = rangeLimits' * cosd(inputAngleBins);
    cornerYCoordinates = rangeLimits' * sind(inputAngleBins);
    xBounds = [min(cornerXCoordinates,[],'all'),max(cornerXCoordinates,[],'all')];
    yBounds = [min(cornerYCoordinates,[],'all'),max(cornerYCoordinates,[],'all')];

    if pad2Square
        xLen = diff(xBounds);
        yLen = diff(yBounds);

        if xLen < squareLen
            padding = (squareLen - xLen)/2;
            xBounds = xBounds + padding*[-1 1];
        elseif xLen > squareLen
            cutoff = (xLen - squareLen)/2;
            xBounds = xBounds + cutoff*[1 -1];
        end

        if yLen < squareLen
            padding = (squareLen - yLen)/2;
            yBounds = yBounds + padding*[-1 1];
        elseif yLen > squareLen
            cutoff = (yLen - squareLen)/2;
            yBounds = yBounds + cutoff*[1 -1];
        end
    end

    % Query points for interpolant
    xOutput = linspace(xBounds(1),xBounds(2),Nx);
    yOutput = linspace(yBounds(1),yBounds(2),Ny);
    [cartx,carty] = meshgrid(xOutput,yOutput);
    
    i = 1;
    for rangeIdx = 1:numel(inputRangeBins)
        for thetaIdx = 1:numel(inputAngleBins)
            range = inputRangeBins(rangeIdx);
            theta = inputAngleBins(thetaIdx);
            x = range * cosd(theta);
            y = range * sind(theta);
            xar(i) = x;
            yar(i) = y;
            var(i) = polarData(rangeIdx, thetaIdx);
            i = i+1;
        end
    end

    F = scatteredInterpolant(xar, yar, var,'linear','none');
    cartData = F(cartx,carty);

end