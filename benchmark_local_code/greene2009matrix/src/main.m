function [final_labels] = main(clusterings, M, k_target)
% clusterings: 每一列代表一个基础聚类结果 (n x M)
% M: 集成规模
% k_target: 目标聚类数目 (如果已知)

    [n, ~] = size(clusterings);
    
    % --- 1. 构建中间矩阵 X ---
    % X 的每一行是一个原始聚类，每一列是一个对象 [cite: 403, 404]
    X_parts = cell(1, M);
    for i = 1:M
        % 将类别标签转换为二进制成员矩阵 [cite: 402]
        unique_labels = unique(clusterings(:, i));
        num_clusters = length(unique_labels);
        Mi = zeros(n, num_clusters);
        for j = 1:num_clusters
            Mi(clusterings(:, i) == unique_labels(j), j) = 1;
        end
        X_parts{i} = Mi'; % 转置后堆叠 [cite: 403]
    end
    X = cell2mat(X_parts'); % 维度: l x n

    % --- 2. 矩阵分解 (NMF) ---
    % 使用论文推荐的乘法更新规则 [cite: 418, 419, 420]
    % 这里的 k' 可以由传入的 k_target 指定，或调用 modelSelection 函数
    k_prime = k_target; 
    
    % NNDSVD 初始化 
    [W0, H0] = nndsvd_init(X, k_prime); 
    
    % 执行迭代更新
    max_iter = 500;
    tol = 1e-6;
    P = W0;
    H = H0;
    
    for iter = 1:max_iter
        % 更新 H [cite: 420]
        H = H .* ((P' * X) ./ (max(P' * P * H, 1e-9)));
        % 更新 P [cite: 419]
        P = P .* ((X * H') ./ (max(P * H * H', 1e-9)));
        
        % 检查收敛 (Frobenius norm) [cite: 416]
        if iter > 1 && norm(X - P*H, 'fro') < tol
            break;
        end
    end

    % --- 3. 生成最终标签 ---
    % 根据 H 矩阵的列向量最大值进行分配 
    [~, final_labels] = max(H, [], 1);
    final_labels = final_labels';
end