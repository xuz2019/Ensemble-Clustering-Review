function [best_labels] = main(clusterings, M, k_target)
% clusterings: [N, H] 矩阵
% M: 集成规模
% k_target: 目标聚类数

[N, H] = size(clusterings);

% 1. 处理缺失值 (2004年论文特别强调了对 incomplete data 的处理)
% 假设缺失值用 0 或 NaN 表示，统一设为 0
clusterings(isnan(clusterings)) = 0;

% 预处理标签
K_j = zeros(1, H);
for j = 1:H
    unique_labels = unique(clusterings(:,j));
    unique_labels(unique_labels==0) = []; % 排除缺失值标记
    K_j(j) = length(unique_labels);
    % 映射标签到 1:K_j
    [~, ~, temp_labels] = unique(clusterings(:,j));
    if any(clusterings(:,j) == 0)
        clusterings(:,j) = temp_labels - 1; % 0 依然是 0，代表缺失
    else
        clusterings(:,j) = temp_labels;
    end
end

max_iter = 150; % 2004年论文提到通常在极少迭代内收敛
tol = 1e-6;
best_loglik = -inf;
best_labels = ones(N, 1);

num_runs = 20; 

for run = 1:num_runs
    % --- 2. 差异化初始化 (2004年论文逻辑) ---
    % alpha: 混合系数 (每个共识簇的先验概率)
    alpha = rand(1, k_target);
    alpha = alpha / sum(alpha);
    
    % theta: 2004年论文公式 (3) (4)
    theta = cell(1, H);
    for j = 1:H
        % 每一行代表一个共识簇 m 在分区 j 下产生各标签的概率分布
        t = rand(k_target, K_j(j));
        theta{j} = t ./ sum(t, 2);
    end
    
    prev_loglik = -inf;
    
    for iter = 1:max_iter
        % --- 3. E-step (公式 7) ---
        % 计算每个样本对每个混合成分的归属感
        E_z = zeros(N, k_target);
        log_prob = zeros(N, k_target);
        
        for m = 1:k_target
            l_comp = log(alpha(m) + 1e-12);
            for j = 1:H
                idx_present = clusterings(:, j) > 0; % 仅处理非缺失数据
                labels = clusterings(idx_present, j);
                % 2004年论文模型：对于缺失位，该项概率贡献为 1 (log为0)
                l_comp_j = zeros(N, 1);
                l_comp_j(idx_present) = log(theta{j}(m, labels)' + 1e-12);
                l_comp = l_comp + l_comp_j;
            end
            log_prob(:, m) = l_comp;
        end
        
        % 数值稳定处理
        max_lp = max(log_prob, [], 2);
        prob_normalized = exp(log_prob - max_lp);
        sum_p = sum(prob_normalized, 2);
        E_z = prob_normalized ./ sum_p;
        
        % 对数似然
        loglik = sum(log(sum_p) + max_lp);
        if abs(loglik - prev_loglik) < tol, break; end
        prev_loglik = loglik;
        
        % --- 4. M-step (公式 8) ---
        sum_Ez = sum(E_z, 1);
        alpha = sum_Ez / N;
        
        for j = 1:H
            for m = 1:k_target
                % 2004年论文特别提到，只根据“观测到”的标签更新 theta
                for k = 1:K_j(j)
                    mask = (clusterings(:, j) == k);
                    if any(mask)
                        theta{j}(m, k) = (E_z(mask, m)' * ones(sum(mask), 1)) / (sum_Ez(m) + 1e-12);
                    else
                        theta{j}(m, k) = 1/K_j(j); % 兜底
                    end
                end
                % 归一化
                theta{j}(m, :) = theta{j}(m, :) / (sum(theta{j}(m, :)) + 1e-12);
            end
        end
    end
    
    if loglik > best_loglik
        best_loglik = loglik;
        [~, best_labels] = max(E_z, [], 2);
    end
end
end