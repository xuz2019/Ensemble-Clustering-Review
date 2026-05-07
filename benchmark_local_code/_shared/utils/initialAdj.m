function adjacencies = initialAdj(baseCls, M, N)
    adjacencies = zeros(N,N,M);
    for i=1:M
        bcParNum = length(unique(baseCls(:, i)));
        link = eye(bcParNum);
        adjacencies(:,:,i) = link(baseCls(:, i), baseCls(:,i));
    end
end

