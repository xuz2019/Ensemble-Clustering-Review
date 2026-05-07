function [result_label] = main(clusterings, M, k)
    % clusterings: n x M 的基本划分矩阵
    % M: 集成规模
    % k: 聚类数目
    
    % --- 1. 参数初始化 (严格遵循论文 Section 4 默认设置) ---
    lambda1 = 1;      
    lambda2 = 0.01;   
    
    % 视图处理：如果输入是单视图集成，m=1
    m = 1; 
    [n, ~] = size(clusterings);
    
    % --- 2. 计算共向矩阵 S ---
    % 论文公式 (1): S_ij = 1/r * sum(delta(pi_i, pi_j))
    S = cell(m, 1);
    for v = 1:m
        S{v} = compute_co_association(clusterings);
    end
    
    % --- 3. 变量初始化 ---
    J = zeros(n, n);
    Z = zeros(n, n);
    Lambda = zeros(n, n);
    E = cell(m, 1);
    Y = cell(m, 1);
    for v = 1:m
        E{v} = zeros(n, n);
        Y{v} = zeros(n, n);
    end
    
    % 初始化 H 为谱聚类初始矩阵 (前 k 个特征向量)
    [H, ~, ~] = svd(randn(n, k), 'econ');
    w = zeros(n, 1);
    
    mu = 1e-3;
    mu_max = 1e10;
    rho = 1.1;
    epsilon = 1e-6;
    max_iter = 100;
    
    % --- 4. 优化迭代 (Algorithm 1) ---
    for t = 1:max_iter
        % Step A: 更新 J (SVT 算子)
        temp_J = Z + Lambda / mu;
        [U, Sigma, V] = svd(temp_J, 'econ');
        diagS = diag(Sigma);
        th = lambda1 / mu;
        diagS = max(diagS - th, 0);
        J = U * diag(diagS) * V';
        
        % Step B: 更新 Z 
        % 修正 pdist2 报错：使用你本地支持的 'squaredeuclidean'
        % 或者直接使用矩阵运算加速：dist(H)_ij = ||hi - hj||^2
        diagHH = sum(H.^2, 2);
        P = bsxfun(@plus, diagHH, diagHH') - 2 * (H * H');
        
        % 计算梯度 F
        F = P / (2 * mu);
        Sum_Sv_t_Sv = zeros(n, n);
        for v = 1:m
            % 论文核心约束：S{v}*Z + E{v} = S{v} + H*H'
            diff_v = S{v} * Z + E{v} - S{v} - H * H' - Y{v} / mu;
            F = F + S{v}' * diff_v;
            Sum_Sv_t_Sv = Sum_Sv_t_Sv + S{v}' * S{v};
        end
        F = F + (Z - J + Lambda / mu) + (Z * ones(n, 1) - 1 + w / mu) * ones(1, n);
        
        % 线性化步长 eta
        eta = norm(Sum_Sv_t_Sv, 'fro') + 1 + n; 
        Z = max(Z - F / eta, 0); % 投影保证非负性
        
        % Step C: 更新 E(v) (软阈值算子)
        for v = 1:m
            temp_E = S{v} - S{v} * Z + H * H' + Y{v} / mu;
            E{v} = max(abs(temp_E) - lambda2 / mu, 0) .* sign(temp_E);
        end
        
        % Step D: 更新 H (谱约束优化)
        % 求解 (Dz - Z)h = lambda*h
        Dz = diag(sum(Z, 2));
        Lz = Dz - (Z + Z')/2; 
        [V_spec, D_spec] = eig(Lz);
        [~, ind] = sort(diag(D_spec), 'ascend');
        H = V_spec(:, ind(1:k)); % 取最小的 k 个特征向量
        
        % Step E: 更新拉格朗日乘子
        for v = 1:m
            Y{v} = Y{v} + mu * (S{v} - S{v} * Z - E{v} + H * H');
        end
        Lambda = Lambda + mu * (Z - J);
        w = w + mu * (Z * ones(n, 1) - 1);
        
        % 更新惩罚参数 mu
        mu = min(mu * rho, mu_max);
        
        % 检查收敛 (Z 和 J 的差异)
        if t > 1 && norm(Z - J, 'inf') < epsilon
            break;
        end
    end
    
    % --- 5. 最终聚类结果 ---
    result_label = kmeans(H, k, 'MaxIter', 100, 'Replicates', 10);
end

% 优化后的共向矩阵计算函数
function S = compute_co_association(clusterings)
    [n, r] = size(clusterings);
    S = zeros(n, n);
    for i = 1:r
        % 获取当前划分的所有类别
        [~, ~, label_idx] = unique(clusterings(:, i));
        % 构造稀疏指示矩阵
        G = sparse(1:n, label_idx, 1, n, max(label_idx));
        % S = S + G*G' (G*G' 的 (i,j) 为 1 表示 i,j 在同一簇)
        S = S + full(G * G');
    end
    S = S / r;
end