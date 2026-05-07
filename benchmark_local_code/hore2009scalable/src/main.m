function [final_labels] = main(clusterings, M, k)
    % 严格按照论文 3.1 节 Bipartite Merger (BM) 逻辑实现 [cite: 743]
    % 输入: 
    %   clusterings: 基聚类标签矩阵 (n x M)
    %   M: 集成规模 (r) [cite: 746]
    %   k: 目标聚类数 (k) [cite: 745]
    
    [bcs, baseClsSegs] = getAllSegs(clusterings);
    data = baseClsSegs';
    [n, dim] = size(data);

    % --- 步骤 1: 提取基聚类中心 (Base Centroids) ---
    % 对应论文 [cite: 744, 745]
    base_centroids = cell(1, M);
    for i = 1:M
        labels_i = clusterings(:, i);
        centroids_i = zeros(k, dim);
        % 确保标签从1开始，如果包含0则需要平移
        if min(labels_i) == 0, labels_i = labels_i + 1; end
        
        for j = 1:k
            idx = (labels_i == j);
            if any(idx)
                centroids_i(j, :) = mean(data(idx, :), 1);
            end
        end
        base_centroids{i} = centroids_i;
    end

    % --- 步骤 2: 构建共识链 (Consensus Chains) ---
    % 论文逻辑：选取一个参考，逐个使用匈牙利算法匹配剩余分区 [cite: 748, 766, 768]
    
    % 初始化：选取第一个分区的中心作为参考中心 (Reference)
    reference_centroids = base_centroids{1}; 
    % chains 用于存储每个链条中的所有中心点坐标
    chains = cell(k, 1);
    for j = 1:k
        chains{j} = reference_centroids(j, :);
    end

    % 迭代匹配剩余的 M-1 个分区 [cite: 768]
    for i = 2:M
        current_centroids = base_centroids{i};
        
        % 计算参考中心与当前中心之间的 Euclidean 距离矩阵 (k x k) [cite: 761]
        dist_matrix = zeros(k, k);
        for r_idx = 1:k
            for c_idx = 1:k
                dist_matrix(r_idx, c_idx) = norm(reference_centroids(r_idx, :) - current_centroids(c_idx, :));
            end
        end
        
        % 线性指派问题 (Linear Assignment Problem)
        % 论文使用 Hungarian Method 实现最小权重完美匹配 [cite: 765]
        % MATLAB R2019b+ 推荐使用自带的 matchpairs
        assignment_indices = matchpairs(dist_matrix, 1e10, 'min');
        
        % 将匹配到的中心加入对应的共识链中 [cite: 767, 772]
        % assignment_indices(row, :) 对应 [参考中心索引, 当前分区中心索引]
        for row = 1:size(assignment_indices, 1)
            ref_idx = assignment_indices(row, 1);
            cur_idx = assignment_indices(row, 2);
            chains{ref_idx} = [chains{ref_idx}; current_centroids(cur_idx, :)];
        end
    end

    % --- 步骤 3: 计算全局中心 (Global Centroids) ---
    % 计算共识链中中心点的算术平均值 [cite: 769]
    global_centroids = zeros(k, dim);
    for j = 1:k
        global_centroids(j, :) = mean(chains{j}, 1);
    end

    % --- 步骤 4: 最终分配 (Final Partition) ---
    % 将所有数据点指派给最近的全局中心 [cite: 773]
    final_labels = zeros(n, 1);
    for i = 1:n
        % 计算点到所有全局中心的欧氏距离平方
        dists = sum((global_centroids - data(i, :)).^2, 2);
        [~, min_idx] = min(dists);
        final_labels(i) = min_idx;
    end
end