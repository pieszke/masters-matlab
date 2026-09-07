classdef CFAR < handle
    properties (Access = private)
        detector
        CUTIdx
        ranges
        mask
        partial
    end

    methods
        function obj = CFAR(guardCells,trainCells,fapOrThr,method,analysisMask)
            if fapOrThr<1
                params={"ProbabilityFalseAlarm",fapOrThr};
            else
                params={"ThresholdFactor","Custom","CustomThresholdFactor",fapOrThr};
            end

            obj.detector = phased.CFARDetector2D("Method", method, "GuardBandSize", guardCells, ...
                "TrainingBandSize", trainCells, params{:});
            [xMax, yMax] = size(analysisMask);
            offset = obj.detector.TrainingBandSize + obj.detector.GuardBandSize + 1;
            obj.ranges = {offset(1):(xMax - offset(1)),offset(2):(yMax - offset(2))};
            [columnInds,rowInds] = meshgrid(obj.ranges{2},obj.ranges{1});
            mask = analysisMask(obj.ranges{1},obj.ranges{2});
            obj.CUTIdx = [rowInds(mask) columnInds(mask)]';
            obj.mask = zeros(xMax, yMax, "logical");
        end

        function [detections,mask] = runCFAR2D(obj,data)
            dets=obj.detector(data, obj.CUTIdx);
            detections=obj.CUTIdx(:,dets);
            mask = obj.mask;
            mask(sub2ind(size(mask),detections(1,:),detections(2,:))) = true;
        end
    end
end