function show2D(X,Y,Z,colors, xLabel,yLabel)
arguments
    X (1,:)
    Y (1,:)
    Z (:,:)
    colors  (1,:) char {mustBeMember(method,{'linear','cubic','spline'})} = 'linear'
    xLabel string = ""
    yLabel string = ""
end
imagesc(X, Y, Z);
% view([0, 90])
if xLabel~=""
    xlabel(xLabel)
end
if yLabel~=""
    ylabel(yLabel)
end
end