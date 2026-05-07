function [results] = main(clusterings, M, k)
    % clusterings: 基础聚类矩阵 (N x M)，N是样本数，M是基划分数量
    % M: 基划分数量 (ensemble size)
    % k: 期望的目标聚类数目
    
    [N, ~] = size(clusterings);
    U = (1:N)';                 % 初始数据集索引
    results = zeros(N, 1);      % 存储最终聚类标签
    CNC = 1;                    % 当前已确定的簇计数
    CNode = U;                  % 当前剩余的数据点索引
    
    % HCEKG 主循环 
    while CNC < k && ~isempty(CNode)
        % 1. 计算每个基划分的知识粒度 GK(pi) [cite: 89, 162]
        H = size(clusterings, 2);
        current_P = clusterings(CNode, :);
        GK = zeros(H, 1);
        for i = 1:H
            GK(i) = computeGK(current_P(:, i));
        end
        
        % 2. 计算 TMRKG 以确定分裂划分 [cite: 134, 162]
        TMRKG = zeros(H, 1);
        for i = 1:H
            sum_MRKG = 0;
            for j = 1:H
                if i ~= j
                    sum_MRKG = sum_MRKG + computeMRKG(current_P(:, i), current_P(:, j), GK(j));
                end
            end
            TMRKG(i) = sum_MRKG / (H - 1); % Eq. (9) [cite: 143]
        end
        
        % 选出最小 TMRKG 的划分 [cite: 150]
        [~, split_idx] = min(TMRKG);
        best_p = current_P(:, split_idx);
        
        % 3. 在选定的划分中，计算每个簇的凝聚度 (Density) [cite: 157, 162]
        unique_labels = unique(best_p);
        densities = zeros(length(unique_labels), 1);
        for i = 1:length(unique_labels)
            Y_idx = CNode(best_p == unique_labels(i));
            densities(i) = computeDensity(clusterings(Y_idx, :)); % Eq. (11) [cite: 157]
        end
        
        % 4. 选择密度最大的簇输出 [cite: 163]
        [~, max_den_idx] = max(densities);
        target_label = unique_labels(max_den_idx);
        Y_final_idx = CNode(best_p == target_label);
        
        % 标记结果并从当前数据集中移除
        results(Y_final_idx) = CNC;
        CNode = setdiff(CNode, Y_final_idx);
        CNC = CNC + 1;
    end
    
    % 5. 处理最后一个簇 [cite: 166]
    if ~isempty(CNode)
        results(CNode) = k;
    end
end

%% 辅助函数：计算知识粒度 GK [cite: 89]
function gk = computeGK(partition)
    n = length(partition);
    [~, ~, labels] = unique(partition);
    counts = histcounts(labels, 1:max(labels)+1);
    gk = sum(counts.^2) / (n^2); % Eq. (1)
end

%% 辅助函数：计算平均粗糙知识粒度 MRKG [cite: 139]
function mrkg = computeMRKG(pi, pj, gk_pj)
    % pi, pj 为两个划分向量
    unique_i = unique(pi);
    num_vi = length(unique_i);
    sum_gamma = 0;
    
    for i = 1:num_vi
        X = (pi == unique_i(i)); % 簇 X
        % 计算粗糙度 gamma [cite: 125]
        % 下近似：pj中完全包含在X中的簇的并集
        % 上近似：pj中与X有交集的簇的并集
        unique_j = unique(pj);
        lower_size = 0;
        upper_size = 0;
        for j = 1:length(unique_j)
            Y = (pj == unique_j(j));
            if all(X(Y)) % Y ⊆ X
                lower_size = lower_size + sum(Y);
            end
            if any(X & Y) % Y ∩ X ≠ ∅
                upper_size = upper_size + sum(Y);
            end
        end
        
        roughness = (1 - lower_size/upper_size) * gk_pj; % Eq. (6)
        sum_gamma = sum_gamma + roughness;
    end
    mrkg = sum_gamma / num_vi; % Eq. (8)
end

%% 辅助函数：计算凝聚度 Density [cite: 157, 158]
function d = computeDensity(Y_clusterings)
    % Y_clusterings 为簇 Y 在所有基划分下的标签矩阵 (n_y x M)
    [~, H] = size(Y_clusterings);
    sum_gk = 0;
    for i = 1:H
        sum_gk = sum_gk + computeGK(Y_clusterings(:, i));
    end
    d = sum_gk; % Eq. (11)
end