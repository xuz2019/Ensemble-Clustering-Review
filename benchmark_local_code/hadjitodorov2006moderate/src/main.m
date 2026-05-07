function [results1, D_np3] = main(clusterings, M, k)

    % 1. 生成共识结果 (Pairwise Co-association + Single Linkage)
    % 论文 Section 4: 使用共识矩阵进行聚类
    [bcs, baseClsSegs] = getAllSegs(clusterings);
    CA = getCA(baseClsSegs, M);
    s = squareform(CA - diag(diag(CA)),'tovector');
    d = 1 - s;
    results1 = cluster(linkage(d,'average'),'maxclust',k);
    
    % 2. 计算多样性度量 D_np3 (基于论文 Eq. 11-13)
    % 计算每个成员与共识结果 P_star 的相似度 (ARI)
    ar_vals = zeros(M, 1);
    for i = 1:M
        ar_vals(i) = MyAdjustedRandIndex(clusterings(:,i), results1);
    end
    
    D_np1 = mean(1 - ar_vals);        % 平均多样性
    D_np2 = std(1 - ar_vals);         % 多样性标准差
    D_np3 = 0.5 * (1 - D_np1 + D_np2); % 论文推荐的折中度量

end

