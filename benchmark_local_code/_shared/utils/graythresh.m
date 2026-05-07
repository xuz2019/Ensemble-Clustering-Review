function level = graythresh(I)
%GRAYTHRESH Otsu threshold without requiring the image toolbox.

values = double(I(:));
values = values(isfinite(values));

if isempty(values)
    error('graythresh:EmptyInput', 'Input must contain at least one finite value.');
end

minValue = min(values);
maxValue = max(values);

if maxValue <= minValue
    level = minValue;
    return;
end

values = (values - minValue) / (maxValue - minValue);
numBins = 256;
edges = linspace(0, 1, numBins + 1);
counts = histcounts(values, edges);

if sum(counts) == 0
    level = minValue;
    return;
end

probabilities = counts / sum(counts);
omega = cumsum(probabilities);
mu = cumsum(probabilities .* (1:numBins));
muTotal = mu(end);

sigmaB2 = (muTotal * omega - mu).^2 ./ max(omega .* (1 - omega), eps);
[~, bestIdx] = max(sigmaB2);

levelNorm = (bestIdx - 1) / (numBins - 1);
level = minValue + levelNorm * (maxValue - minValue);
end
