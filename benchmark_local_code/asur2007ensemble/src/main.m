function [final_labels] = main(clusterings, M, k)
    % 输入:
    % clusterings: 基础聚类成员矩阵 (n x M)
    % M: 基础聚类数量
    % k: 目标聚类数
    
    n = size(clusterings, 1);
    
    %% 阶段 1: 聚类提纯 (Cluster Purification/Pruning) [cite: 130, 142]
    % 注意：根据论文，这里需要 PPI 原始网络的拓扑结构来计算 Reliability。
    % 假设您已经计算好了可靠的聚类，或者此处通过二进制矩阵表示。
    % 这里演示将所有 M*k 个聚类转换为成员矩阵 [cite: 144, 145]
    
    binary_matrix = [];
    for i = 1:M
        member = clusterings(:, i);
        unique_labels = unique(member);
        for j = 1:length(unique_labels)
            % 构造 indicator function [cite: 146]
            col = (member == unique_labels(j));
            binary_matrix = [binary_matrix, col];
        end
    end
    
    %% 阶段 2: 降维 (Dimensionality Reduction - Logistic PCA) [cite: 150, 159]
    % 论文指出，由于成员矩阵非常稀疏且冗余，使用 PCA 提取特征 [cite: 158, 161]。
    % 这里使用 MATLAB 自带的 PCA 或针对二进制数据的逻辑 PCA 简化版
    [~, score, ~] = pca(full(double(binary_matrix)));
    
    % 保留能够反映主要判别信息的维度 (例如前 20-50 维) [cite: 161, 162]
    reduced_data = score(:, 1:min(50, size(score,2)));
    
    %% 阶段 3: 共识聚类 (Consensus Clustering) [cite: 163]
    % 论文推荐使用 Recursive Bisection (rbr) 或 Agglomerative Hierarchical (PCA-agglo)
    % 这里使用层次聚类 (PCA-agglo) [cite: 164, 166]
    dist_matrix = pdist(reduced_data);
    tree = linkage(dist_matrix, 'average'); % 对应论文中的 PCA-agglo [cite: 172]
    final_labels = cluster_custom(tree, k); % 这里的 k 是目标聚类数
end

function labels = cluster_custom(tree, k)
    labels = cluster(tree, 'maxclust', k);
end