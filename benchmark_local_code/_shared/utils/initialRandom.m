function bcIdx = initialRandom(poolSize, M, cntTimes)
    bcIdx = zeros(cntTimes, M);
    for i = 1:cntTimes
        tmp = randperm(poolSize);
        bcIdx(i,:) = tmp(1:M);
    end
end

