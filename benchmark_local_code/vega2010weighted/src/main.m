function [consensus_partition] = main(clusterings, M, k)
    % clusterings: n x M 的矩阵，每一列是一个分区结果
    % M: 分区数量
    % k: 目标聚类数
    
    [n, M_actual] = size(clusterings);
    
    %% 第一步：权重计算 (CLK模式)
    weights = compute_weights(clusterings, 'CLK'); 

    %% 第二步：初始化并强制标签归一化
    % 随机选择一个初始分区
    init_idx = randi(M_actual);
    current_partition = clusterings(:, init_idx);
    
    % 【关键修改 1】：强制将初始分区的标签映射到 1:k 范围内
    % 即使原始标签是 [10, 20, 30]，也会被重新映射为 [1, 2, 3]
    [~, ~, current_partition] = unique(current_partition);
    
    % 如果映射后的类数不等于 k，则随机调整部分点以满足 k
    if max(current_partition) > k
        current_partition(current_partition > k) = randi(k, sum(current_partition > k), 1);
    end

    best_partition = current_partition;
    best_energy = compute_objective(best_partition, clusterings, weights);
    
    %% 第三步：模拟退火寻找最佳共识分区
    % 参数设置 (参考论文 4.3 节)
    T0 = 100.0;
    beta = 0.98;
    rMax = 10000;
    T_min = 1e-4;
    % T0 = 10.0;       % 优化后的参数
    % beta = 0.90;     
    % rMax = 2000;     
    % T_min = 1e-2;    
    
    T = T0;
    
    for r = 1:rMax
        % 产生邻域解
        new_partition = current_partition;
        
        % 【关键修改 2】：增加扰动步长
        % 每次只改一个点在大样本下太慢，改为随机选取 1% 的点进行变异
        change_idx = randperm(n, max(1, round(n * 0.01)));
        
        % 【关键修改 3】：严格限制新标签在 [1, k] 集合内
        new_partition(change_idx) = randi(k, length(change_idx), 1);
        
        % 计算新能量
        new_energy = compute_objective(new_partition, clusterings, weights);
        
        % Metropolis 准则
        delta_e = new_energy - best_energy;
        if delta_e > 0 || rand < exp(delta_e / T)
            current_partition = new_partition;
            if new_energy > best_energy
                best_energy = new_energy;
                best_partition = new_partition;
            end
        end
        
        % 降温
        T = T * beta;
        if T < T_min, break; end
    end
    
    % 最终输出前再次检查，确保标签是连续且在 k 之内的
    [~, ~, consensus_partition] = unique(best_partition);
end