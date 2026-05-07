function sim = wpck_kernel(P1, P2)
    % 实现论文中的归一化核函数 \tilde{k}(Pi, Pj) [cite: 658]
    % P1, P2 为 n x 1 的标签向量
    
    k11 = compute_k(P1, P1);
    k22 = compute_k(P2, P2);
    k12 = compute_k(P1, P2);
    
    % 公式 (8): \tilde{k} = k(P1, P2) / sqrt(k(P1,P1) * k(P2,P2))
    sim = k12 / sqrt(k11 * k22);
end

function k_val = compute_k(Pi, Pj)
    % 实现公式 (9): k(Pi, Pj) = \sum_{S \subseteq X} \delta... 
    % 注意：直接遍历所有子集是不可行的。
    % 根据论文 3.2 节推导，k(Pi, Pj) 与分区之间的重叠矩阵（Contingency Matrix）相关。
    % 这里使用论文定义的显著性度量 \mu(S|P) = |S|/|C| [cite: 648] 的简化矩阵形式：
    
    n = length(Pi);
    uP = unique(Pi);
    uQ = unique(Pj);
    
    k_val = 0;
    % 遍历 Pi 和 Pj 的所有聚类组合
    for i = 1:length(uP)
        cluster_i = (Pi == uP(i));
        size_i = sum(cluster_i);
        for j = 1:length(uQ)
            cluster_j = (Pj == uQ(j));
            size_j = sum(cluster_j);
            
            % 计算交集大小
            overlap = sum(cluster_i & cluster_j);
            if overlap > 0
                % 根据论文定义的 \mu(S|P) 逻辑，相似度取决于共同包含的元素比例
                % 实际复现中常采用其等价的矩阵标量积形式
                k_val = k_val + (overlap^2) / (size_i * size_j);
            end
        end
    end
end