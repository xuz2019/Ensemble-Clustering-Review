function [labels] = myKCC_Core(dataset, K, w, clusters_per_partition)
    [n, ~] = size(dataset);
    cumulated = cumsum(clusters_per_partition);
    
    % 随机初始化质心 (从唯一的样本中选取)
    unique_rows = unique(dataset, 'rows');
    rand_idx = randperm(size(unique_rows, 1), K);
    centroids = unique_rows(rand_idx, :);
    
    labels_old = zeros(n, 1);
    max_iter = 100;
    
    for iter = 1:max_iter
        % --- 步骤 1: 分配阶段 (Assignment) ---
        % 计算每个点到质心的加权距离
        distances = zeros(n, K);
        for k_idx = 1:K
            dist_val = 0;
            idx1 = 1;
            for m = 1:length(clusters_per_partition)
                idx2 = cumulated(m);
                % 使用平方欧氏距离 (对应论文中的 U_c 度量)
                sub_sample = dataset(:, idx1:idx2);
                sub_centroid = centroids(k_idx, idx1:idx2);
                
                % 计算该样本段的平方误差
                d = sum((sub_sample - sub_centroid).^2, 2);
                dist_val = dist_val + w(m) * d;
                
                idx1 = idx2 + 1;
            end
            distances(:, k_idx) = dist_val;
        end
        
        [~, labels] = min(distances, [], 2);
        
        % 检查收敛
        if isequal(labels, labels_old)
            break;
        end
        labels_old = labels;
        
        % --- 步骤 2: 更新阶段 (Update) ---
        % 根据 Lemma 1，质心通过列联矩阵计算
        idx1 = 1;
        for m = 1:length(clusters_per_partition)
            idx2 = cumulated(m);
            % 对每一个基础划分块，更新质心分量
            for k_idx = 1:K
                points_in_cluster = (labels == k_idx);
                if any(points_in_cluster)
                    % 质心即为该簇内二值特征的均值
                    centroids(k_idx, idx1:idx2) = mean(dataset(points_in_cluster, idx1:idx2), 1);
                end
            end
            idx1 = idx2 + 1;
        end
    end
end