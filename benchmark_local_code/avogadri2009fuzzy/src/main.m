function [final_labels] = main(data, M, k)
    % 输入:
    % data: d x n 原始数据矩阵 (每列是一个样本) [cite: 403]
    % M: 集成规模 (基聚类数量 c) [cite: 405]
    % k: 聚类簇数 [cite: 404]
    
    [d, n] = size(data);
    epsilon = 0.2; % 论文实验中使用的失真度 [cite: 466]
    
    % 计算投影维度 d' (基于 JL 引理) [cite: 358, 425]
    % d' >= c * log(n) / epsilon^2
    % 注意：实际操作中常取一个固定比例或经验值，此处按引理估算
    d_prime = ceil(4 * log(n) / (epsilon^2)); 
    if d_prime >= d, d_prime = floor(d/2); end % 防止维度未减少 [cite: 373]

    cum_M = zeros(n, n); % 累积相似度矩阵 M^C [cite: 411]
    fuzziness = 1.1; % 论文中测试的模糊系数 [cite: 471]

    % --- 步骤 2-6: 生成基聚类并聚合 ---
    for t = 1:M
        % (3-4) 生成投影矩阵并投影数据 [cite: 414, 415]
        % 使用正态随机投影 (Normal Random Projections) 
        R = (1/sqrt(d_prime)) * randn(d_prime, d); 
        Dt = R * data; 
        
        % (5) 应用模糊 k-means (FCM) [cite: 416, 429]
        % MATLAB 自带 fcm 函数输出 U 为 k x n
        options = [fuzziness; 100; 1e-5; 0];
        [~, U] = fcm(Dt', k, options);
        
        % (6) 使用模糊 t-norm (代数乘积) 计算相似度矩阵 [cite: 380, 418, 442]
        % Mt(i,j) = sum_{s=1}^k (U_si * U_sj)
        Mt = U' * U; 
        
        % 累加相似度 [cite: 420]
        cum_M = cum_M + Mt;
    end
    
    % (7) 计算平均相似度矩阵 M^C [cite: 420, 431]
    MC = cum_M / M;
    
    % (8) 共识聚类：对 MC 的行再次应用 FCM [cite: 421, 432]
    % 此时 MC 的每一行被视为新的特征空间 [cite: 389]
    [~, U_final] = fcm(MC, k, options);
    
    % --- 最终标签获取 (模糊转硬划分) ---
    % 采用论文中的 fuzzy-max 策略 (Eq. 4) [cite: 393, 436]
    [~, final_labels] = max(U_final, [], 1);
    final_labels = final_labels'; % 转为列向量以匹配评估函数
end