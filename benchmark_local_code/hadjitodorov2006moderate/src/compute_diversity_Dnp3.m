function D_np3 = compute_diversity_Dnp3(partitions, P_star)
    L = size(partitions, 2);
    ar_vals = zeros(L, 1);
    
    % 计算每个成员与共识结果 P* 的相似度 (Adjusted Rand Index)
    for i = 1:L
        ar_vals(i) = MyAdjustedRandIndex(partitions(:,i), P_star);
    end
    
    % D_np1: 平均个体多样性 [cite: 483]
    D_np1 = mean(1 - ar_vals);
    
    % D_np2: 个体多样性的标准差 [cite: 486]
    D_np2 = std(1 - ar_vals);
    
    % D_np3: 论文提出的折中度量 [cite: 492]
    D_np3 = 0.5 * (1 - D_np1 + D_np2);
end