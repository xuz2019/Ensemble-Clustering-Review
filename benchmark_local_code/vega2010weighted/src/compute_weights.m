function weights = compute_weights(clusterings, mode)
    [n, m] = size(clusterings);
    % PVI (Property Validity Indexes)
    % 论文实验使用了 Variance, Connectivity, Silhouette, Dunn Index [cite: 291]
    % 如果你没有原始数据，只能基于分区间的核相似度（PTC）计算权重
    
    % 这里演示基于“分区一致性”的 CLK 权重计算逻辑 (公式 3)
    PVIs = zeros(m, 1);
    for i = 1:m
        sim_sum = 0;
        for j = 1:m
            if i ~= j
                % 使用论文定义的核相似度替代 NMI
                sim_sum = sim_sum + wpck_kernel(clusterings(:,i), clusterings(:,j));
            end
        end
        PVIs(i) = sim_sum / (m-1); % 该分区与其他分区的平均相似度
    end
    
    Aj = sum(PVIs);
    % 计算熵 H(Ij) [cite: 611]
    phi = PVIs / (Aj + eps);
    H = -sum(phi .* log(phi + eps));
    
    % 公式 (3): \omega_i = H * (1 - |PVI_i - Mean(PVI)|) [cite: 617]
    weights = H * (1 - abs(PVIs - Aj/m));
    weights = weights / sum(weights); % 归一化
end