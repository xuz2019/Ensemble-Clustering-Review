function [results] = main(clusterings, M, k)
    % clusterings: n x M 的矩阵，每列是一个划分
    % M: 集成规模
    % k: 目标簇数
    
    [n, ~] = size(clusterings);

    % --- 阶段 1: 累积投票 (cVote) ---
    % 1.1 选择参考划分 (基于最大信息熵原理) [cite: 613, 637]
    H = zeros(1, M);
    for i = 1:M
        H(i) = calculateEntropy(clusterings(:, i));
    end
    [~, o_idx] = max(H);
    U_ref = clusterings(:, o_idx);
    k_o = length(unique(U_ref));
    
    % 1.2 计算映射矩阵 [cite: 586, 638]
    % 目标是计算 n x k_o 的概率矩阵 U_hat
    U_hat = zeros(n, k_o);
    ref_labels = unique(U_ref);
    
    for i = 1:M
        U_i = clusterings(:, i);
        k_i = length(unique(U_i));
        % 计算当前划分与参考划分之间的条件概率 P(c_ref | c_i)
        P_mapping = computeProbMapping(U_i, U_ref, k_i, k_o);
        
        % 累积投票：将硬划分 U_i 映射为基于参考标签的概率表示 [cite: 497, 581]
        U_mapped = zeros(n, k_o);
        labels_i = unique(U_i);
        for j = 1:n
            idx_in_i = find(labels_i == U_i(j));
            U_mapped(j, :) = P_mapping(idx_in_i, :);
        end
        U_hat = U_hat + U_mapped;
    end
    U_hat = U_hat / M; % 取平均得到经验分布 [cite: 586]

    % --- 阶段 2: 信息瓶颈提取 (IB) ---
    % 将 k_o 个组件压缩为 k 个共识簇 [cite: 633, 639]
    % 使用凝聚算法 (AIB)，每次合并使 JS 散度增加最小的两个簇 
    results = agglomerativeIB(U_hat, k);
end

% 辅助函数：计算熵 [cite: 599]
function h = calculateEntropy(labels)
    n = length(labels);
    [~, ~, idx] = unique(labels);
    counts = accumarray(idx, 1);
    p = counts / n;
    h = -sum(p .* log2(p + eps));
end

% 辅助函数：计算概率映射矩阵 P(c_ref | c_i) [cite: 115]
function P = computeProbMapping(U_i, U_ref, k_i, k_o)
    labels_i = unique(U_i);
    labels_ref = unique(U_ref);
    P = zeros(k_i, k_o);
    for a = 1:k_i
        mask_i = (U_i == labels_i(a));
        n_a = sum(mask_i);
        for b = 1:k_o
            n_ab = sum(mask_i & (U_ref == labels_ref(b)));
            P(a, b) = n_ab / n_a; % 概率投票 [cite: 584]
        end
    end
end

% 辅助函数：凝聚式信息瓶颈 (AIB) [cite: 504, 647]
function final_labels = agglomerativeIB(U_hat, target_k)
    [n, k_curr] = size(U_hat);
    % 初始状态：每个组件是一个簇
    % p(x|c) 对应 U_hat 的每一列（归一化后）
    p_c = sum(U_hat, 1) / n;
    p_x_given_c = bsxfun(@rdivide, U_hat, sum(U_hat, 1) + eps)'; 
    
    current_clusters = num2cell(1:k_curr);
    
    while length(current_clusters) > target_k
        min_loss = inf;
        merge_pair = [1, 2];
        
        % 寻找合并后 JS 散度增加最小的对 [cite: 648]
        num_c = length(current_clusters);
        for i = 1:num_c
            for j = i+1:num_c
                % 计算 JS 散度引发的互信息损失 [cite: 650]
                pi1 = p_c(i) / (p_c(i) + p_c(j));
                pi2 = p_c(j) / (p_c(i) + p_c(j));
                js_div = (p_c(i) + p_c(j)) * JS_Divergence(p_x_given_c(i,:), p_x_given_c(j,:), pi1, pi2);
                
                if js_div < min_loss
                    min_loss = js_div;
                    merge_pair = [i, j];
                end
            end
        end
        
        % 执行合并
        i = merge_pair(1); j = merge_pair(2);
        new_p_c = p_c(i) + p_c(j);
        p_x_given_c(i, :) = (p_c(i)/new_p_c)*p_x_given_c(i, :) + (p_c(j)/new_p_c)*p_x_given_c(j, :);
        p_c(i) = new_p_c;
        
        p_x_given_c(j, :) = [];
        p_c(j) = [];
        current_clusters{i} = [current_clusters{i}, current_clusters{j}];
        current_clusters(j) = [];
    end
    
    % 生成最终标签
    final_labels = zeros(n, 1);
    [~, raw_labels] = max(U_hat, [], 2);
    for i = 1:length(current_clusters)
        for old_idx = current_clusters{i}
            final_labels(raw_labels == old_idx) = i;
        end
    end
end

function d = JS_Divergence(p1, p2, pi1, pi2)
    m = pi1*p1 + pi2*p2;
    d = pi1 * KL_Div(p1, m) + pi2 * KL_Div(p2, m);
end

function k = KL_Div(p, q)
    filter = (p > 0);
    k = sum(p(filter) .* log2(p(filter) ./ (q(filter) + eps)));
end