classdef bgFilter < handle
    properties (Access = private)
        index
        history
        sum
        shape
    end
    properties
        value
        length
    end

    methods
        function obj = bgFilter(firstData, filterLength)
            obj.history = zeros(filterLength, numel(firstData));
            obj.length = filterLength;
            obj.shape = size(firstData);
            obj.value = firstData;
            obj.sum = reshape(firstData, [], 1) * obj.length;
            obj.index = 1;
        end

        function newVal = addSample(obj, data)
            if numel(data) ~= size(obj.history, 2)
                error("Invalid data size")
            end
            data = reshape(data, [], 1);
            obj.sum = obj.sum - obj.history(obj.index, :)' + data;
            obj.history(obj.index, :) = data;
            obj.index = mod(obj.index, obj.length) + 1;
            obj.value = reshape(obj.sum./obj.length, obj.shape);
            newVal = obj.value;
        end
        function sampleWithRemovedBg = addSampleNoBg(obj, data, bgFactor)
            val = obj.value;
            obj.addSample(data);
            sampleWithRemovedBg = data - val * bgFactor;
        end
    end
end
