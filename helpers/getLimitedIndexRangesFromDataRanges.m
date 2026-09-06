function [indexArr, croppedRange] = getLimitedIndexRangesFromDataRanges(srcRange, limits)
if iscolumn(limits)
    limits = limits';
end
if xor(isrow(srcRange), isrow(limits))
    [~, startStop] = min(abs(srcRange-limits));
else
    [~, startStop] = min(abs(srcRange'-limits));
end
startStop = sort(startStop);
indexArr = startStop(1):startStop(2);
croppedRange = srcRange(indexArr);
end