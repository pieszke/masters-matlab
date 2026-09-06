function [detections,mask] = runCFAR2D(guardCells,trainCells,fapOrThr,method,data)
% get indexes of limits
if fapOrThr<1
    params={"ProbabilityFalseAlarm",fapOrThr};
else
    params={"ThresholdFactor","Custom","CustomThresholdFactor",fapOrThr};
end

detector = phased.CFARDetector2D("Method", method, "GuardBandSize", guardCells, ...
    "TrainingBandSize", trainCells, params{:});
[xMax, yMax] = size(data);
offset = detector.TrainingBandSize + detector.GuardBandSize + 1;
% create a map of cells to test
[columnInds,rowInds] = meshgrid(offset(2):(yMax - offset(2)),offset(1):(xMax - offset(1)));
CUTIdx = [rowInds(:) columnInds(:)]';
mask = zeros(xMax,yMax,"logical");
dets=detector(data, CUTIdx);
detections=CUTIdx(:,dets);
mask(offset(1):(xMax - offset(1)), offset(2):(yMax - offset(2))) = reshape(dets,size(rowInds));
end