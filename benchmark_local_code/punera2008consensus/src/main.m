function [consensus_labels] = main(clusterings, M, k)
    % clusterings: n x M 的矩阵 (如果是硬标签) 或 n x (M*k) 的矩阵 (如果是软概率)
    % M: 基聚类个数
    % k: 目标聚类数
    
    [n, cols] = size(clusterings);
    
    % --- 逻辑判断：如果是硬标签，先转换为 Indicator Matrix ---
    if cols == M
        S_full = [];
        for i = 1:M
            S_i = dummyvar(clusterings(:,i)); % 转换为 0-1 概率矩阵
            % 确保维度一致
            if size(S_i, 2) < max(clusterings(:,i))
                 % 补齐缺失的簇列
            end
            S_full = [S_full, S_i];
        end
    else
        S_full = clusterings;
    end

    % --- 严格按照论文第4节归一化 ---
    S = S_full ./ M; 
    
    % --- 多次运行取最优 (防止全部分配到一个簇) ---
    best_obj = inf;
    best_labels = [];
    
    for r = 1:5  % 运行5次，取 KL 目标函数最小的一次
        [labels, obj] = ITK_algorithm_stable(S, k);
        if obj < best_obj && numel(unique(labels)) == k
            best_obj = obj;
            best_labels = labels;
        end
    end
    
    if isempty(best_labels)
        consensus_labels = labels; % 如果都没达到k类，取最后一次
    else
        consensus_labels = best_labels;
    end
end

function [labels, final_obj] = ITK_algorithm_stable(S, k)
    [n, d] = size(S);
    
    % 1. 数值平滑处理 (这是防止全为同一个值的关键)
    % 论文公式中 log(P/Q)，如果 Q 为 0 则会报错。
    % 我们给 S 加上一个极小的扰动量，并重新归一化行
    alpha = 1e-6; 
    S_smooth = S + (alpha / d);
    S_smooth = S_smooth ./ sum(S_smooth, 2); 
    
    % 2. 初始化中心
    % 使用 K-means++ 思想或随机样本点
    rand_idx = randperm(n, k);
    centroids = S_smooth(rand_idx, :);
    
    labels = zeros(n, 1);
    max_iter = 50;
    
    for iter = 1:max_iter
        prev_labels = labels;
        
        % 3. 分配阶段：计算 KL 散度
        % 论文公式 (1): D(x||y) = sum( x * log(x/y) )
        dist_matrix = zeros(n, k);
        for c = 1:k
            % 向量化计算，提高速度并保持数值稳定
            c_center = centroids(c, :);
            % KL = sum( P * logP ) - sum( P * logQ )
            term1 = sum(S_smooth .* log(S_smooth), 2);
            term2 = S_smooth * log(c_center + eps)';
            dist_matrix(:, c) = term1 - term2;
        end
        
        [min_dist, labels] = min(dist_matrix, [], 2);
        
        % 4. 强制处理空簇 (防止所有样本聚为一类)
        for c = 1:k
            if ~any(labels == c)
                % 找距离当前所有中心最远的点
                [~, far_idx] = max(min_dist);
                labels(far_idx) = c;
                centroids(c, :) = S_smooth(far_idx, :);
                min_dist(far_idx) = 0; % 防止重复选取
            end
        end
        
        % 5. 更新中心
        for c = 1:k
            if any(labels == c)
                % 论文公式：新中心是算术平均值
                centroids(c, :) = mean(S_smooth(labels == c, :), 1);
            end
        end
        
        if isequal(labels, prev_labels)
            break;
        end
    end
    
    % 计算目标函数值 (所有点到其中心的 KL 距离之和)
    final_obj = 0;
    for c = 1:k
        idx = (labels == c);
        if any(idx)
            c_center = centroids(c, :);
            p = S_smooth(idx, :);
            final_obj = final_obj + sum(sum(p .* log(p ./ (c_center + eps)), 2));
        end
    end
end