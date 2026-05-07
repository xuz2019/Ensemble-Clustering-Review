function [ensemble_label] = main(clusterings, M, k)
    [n, ~] = size(clusterings);

    % --- Step 1: Finding Neighbors ---
    % 计算共现频率矩阵 S
    S = zeros(n, n);
    for q = 1:M
        % 优化计算：利用等值比较
        S = S + double(bsxfun(@eq, clusterings(:,q), clusterings(:,q)'));
    end
    S = S / M; 

    % Otsu 阈值（如果 S 的值很集中，graythresh 可能不理想，可以手动设为 0.5 或均值）
    try
        t_star = graythresh(S); 
    catch
        t_star = mean(S(:));
    end
    S_prime = S >= t_star;

    % --- Step 2: Cluster Correspondence (严格对齐) ---
    aligned_clusterings = clusterings;
    for q = 2:M
        aligned_clusterings(:, q) = align_process(aligned_clusterings(:, 1), clusterings(:, q), k);
    end

    % --- Step 3 & 4: Mass Functions & DS Combination ---
    % 使用对数累加防止数值下溢
    log_combined_mass = zeros(n, k); 
    eps_val = 1e-10; % 防止 log(0)

    for q = 1:M
        current_partition = aligned_clusterings(:, q);
        mq = zeros(n, k);
        for i = 1:n
            neighbors_idx = S_prime(i, :);
            neighbor_labels = current_partition(neighbors_idx);
            
            % 计算该对象邻居在各个簇的分布
            for c = 1:k
                % 论文核心：m_q^i(C_c) = |N(x_i) \cap C_c^q| / |N(x_i)|
                mq(i, c) = sum(neighbor_labels == c) / length(neighbor_labels);
            end
        end
        
        % 加上平滑项并转为对数进行累加 (对应论文 Eq. 10 的连乘)
        log_combined_mass = log_combined_mass + log(mq + eps_val);
    end

    % 在对数空间取最大值，效果等同于在原始空间取最大乘积
    [~, ensemble_label] = max(log_combined_mass, [], 2);
end

% 对齐函数保持不变
function [new_pi2] = align_process(pi1, pi2, k)
    Overlap = zeros(k, k);
    for i = 1:k
        for j = 1:k
            Overlap(i, j) = sum((pi1 == i) & (pi2 == j));
        end
    end
    
    mapping = zeros(k, 1);
    temp_overlap = Overlap;
    for iter = 1:k
        [max_val, idx] = max(temp_overlap(:));
        [u, v] = ind2sub([k, k], idx);
        mapping(v) = u; 
        temp_overlap(u, :) = -1e-9; % 标记已处理
        temp_overlap(:, v) = -1e-9;
    end
    
    new_pi2 = zeros(size(pi2));
    for j = 1:k
        new_pi2(pi2 == j) = mapping(j);
    end
end