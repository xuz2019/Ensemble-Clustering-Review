function labels = nsc_strict(W, k)
    n = size(W, 1);
    D = diag(sum(W, 2));
    % 归一化拉普拉斯: L = I - D^(-1/2) * W * D^(-1/2)
    D_half = diag(1./sqrt(diag(D) + eps));
    L = eye(n) - D_half * W * D_half;
    
    % 求前 k 个最小特征向量
    [V, ~] = eigs(L, k, 'smallestreal');
    
    % NJW 归一化步骤: 保证每个特征向量在单位球面上
    V_norm = bsxfun(@rdivide, V, sqrt(sum(V.^2, 2) + eps));
    
    % 最后使用 K-means 划分
    labels = kmeans(V_norm, k, 'Replicates', 5);
end