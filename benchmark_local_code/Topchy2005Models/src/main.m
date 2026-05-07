function [best_labels] = main(clusterings, M, k_target)
% clusterings: [N, H] 矩阵，N个样本，H个基础聚类器
% M: 集成规模 (H)
% k_target: 目标聚类数 (k)

[N, H] = size(clusterings);

% 预处理：确保所有标签都是从1开始的连续整数
for j = 1:H
    [~, ~, clusterings(:,j)] = unique(clusterings(:,j));
end

% 统计每个基础聚类器的簇数 K_j
K_j = zeros(1, H);
for j = 1:H
    K_j(j) = max(clusterings(:, j));
end

max_iter = 100;
tol = 1e-6;
best_loglik = -inf;
best_labels = ones(N, 1);

% 论文建议多次运行以避免局部最优
num_runs = 50; 

for run = 1:num_runs
    % --- 1. 初始化 ---
    % 按照论文思路，随机初始化每个样本属于共识簇的概率 alpha
    alpha = ones(1, k_target) / k_target;
    
    % theta{j}(m, k) 表示第 j 个聚类器中，共识簇 m 对应原始标签 k 的概率
    theta = cell(1, H);
    for j = 1:H
        % 随机初始化参数并归一化
        temp_theta = rand(k_target, K_j(j)) + 0.1; % 加微小偏移防止0概率
        theta{j} = temp_theta ./ sum(temp_theta, 2);
    end
    
    prev_loglik = -inf;
    
    for iter = 1:max_iter
        % --- 2. E-step: 计算后验概率 E[z_im] ---
        % 为了数值稳定，我们在对数空间计算
        log_prob = zeros(N, k_target);
        for m = 1:k_target
            % log(alpha_m)
            l_alpha = log(alpha(m) + 1e-10);
            % sum_{j=1 to H} log(theta_{j,m}(y_ij))
            l_theta = zeros(N, 1);
            for j = 1:H
                labels_j = clusterings(:, j);
                % 提取当前共识簇 m 在第 j 个分区下对应的概率
                current_theta_j_m = theta{j}(m, :);
                % 映射每个样本的标签到其概率
                l_theta = l_theta + log(current_theta_j_m(labels_j)' + 1e-10);
            end
            log_prob(:, m) = l_alpha + l_theta;
        end
        
        % Log-Sum-Exp Trick 防止数值溢出
        max_log_prob = max(log_prob, [], 2);
        exp_prob = exp(log_prob - max_log_prob);
        sum_exp_prob = sum(exp_prob, 2);
        
        E_z = exp_prob ./ sum_exp_prob; % 归一化得到后验概率
        
        % 计算当前对数似然
        loglik = sum(log(sum_exp_prob + 1e-10) + max_log_prob);
        
        % 收敛检查
        if abs(loglik - prev_loglik) < tol
            break;
        end
        prev_loglik = loglik;
        
        % --- 3. M-step: 更新参数 ---
        % 更新混合系数 alpha
        sum_Ez = sum(E_z, 1);
        alpha = sum_Ez / N;
        
        % 更新多项式分布参数 theta
        for j = 1:H
            for m = 1:k_target
                denom = sum_Ez(m) + 1e-10;
                for k = 1:K_j(j)
                    % 仅累加在该分区中标签为 k 的样本的后验概率
                    indicator = (clusterings(:, j) == k);
                    theta{j}(m, k) = sum(E_z(indicator, m)) / denom;
                end
                % 保证概率和为1 (平滑处理)
                theta{j}(m, :) = (theta{j}(m, :) + 1e-10) / sum(theta{j}(m, :) + 1e-10);
            end
        end
    end
    
    % 记录最佳似然对应的标签
    if loglik > best_loglik
        best_loglik = loglik;
        [~, best_labels] = max(E_z, [], 2);
    end
end
end