function [final_labels] = main(clusterings, M, K)
    % clusterings: 基础划分矩阵 [n x M]
    % M: 基础划分的数量
    % K: 最终期望的聚类数目
    
    [n, ~] = size(clusterings);
    
    % 1. 构建二值数据集 (Binary Dataset Building)
    % 论文中将每个基础划分转换为 One-hot 编码并拼接
    bin_dataset = [];
    clusters_per_partition = zeros(1, M);
    for i = 1:M
        labels = clusterings(:, i);
        unique_l = unique(labels);
        num_c = length(unique_l);
        clusters_per_partition(i) = num_c;
        
        % 将标签转换为 One-hot 编码 (n x num_c)
        binary_part = dummyvar(categorical(labels));
        bin_dataset = [bin_dataset, binary_part];
    end
    
    % 2. 准备权重 (Weights)
    % 默认使用等权重 1/M
    w = ones(1, M) / M;
    
    % 3. 运行加权 K-means (KCC 核心)
    % 为了防止陷入局部最优，通常运行多次取最优
    best_obj = inf;
    final_labels = [];
    
    trials = 5; % 根据需要调整试验次数
    for t = 1:trials
        labels = myKCC_Core(bin_dataset, K, w, clusters_per_partition);
        
        % 这里可以使用 Calinski-Harabasz 指标或简单的目标函数值来评估
        % 简单起见，这里假设最后一次试验或在 Core 内部处理
        final_labels = labels; 
    end
end