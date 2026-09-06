function show3D(X,Y,Z, xLabel,yLabel,zLabel)
arguments
    X (1,:)
    Y (1,:)
    Z (:,:)
    xLabel string = ""
    yLabel string = ""
    zLabel string = ""
end
surf(X, Y, Z);
% view([0, 90])
shading interp
if xLabel~=""
    xlabel(xLabel)
end
if yLabel~=""
    ylabel(yLabel)
end
if zLabel~=""
    zlabel(zLabel)
end
end