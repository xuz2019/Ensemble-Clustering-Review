function [core, fringe] = diskmeans_single(data, K, alpha, beta)
    % 对应论文 Algorithm 1 [cite: 155]
    % alpha, beta 为距离阈值 [cite: 123]
    [idx, centers] = kmeans(data, K);
    dists = pdist2(data, centers);
    
    core = cell(K, 1);
    fringe = cell(K, 1);
    
    for j = 1:K
        % 论文规则：距离小于 alpha 的入核心域，alpha 到 beta 之间入边界域 [cite: 162, 163]
        % 注意：论文中用的是相似度(v)越大越核心，若用距离则相反
        core{j} = find(dists(:,j) < alpha);
        fringe{j} = find(dists(:,j) >= alpha & dists(:,j) <= beta);
    end
end