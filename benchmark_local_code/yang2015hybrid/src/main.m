function [consensus_partition, alpha_weights] = main(X, T, k, lambda, NB)
    % HSCE: Hybrid Sampling-Based Clustering Ensemble
    % 输入:
    %   X      : 原始数据矩阵 [N x D]
    %   T      : 迭代次数/集成规模 (例如 50 或 100)
    %   k      : 目标聚类簇数
    %   lambda : 正则化系数 (默认 0.5，论文推荐)
    %   NB     : 局部缩放邻居数量 (默认 10)
    % 输出:
    %   consensus_partition : 最终的共识聚类标签 [N x 1]
    %   alpha_weights       : 每一轮生成的分区权重 [1 x T]

    if nargin < 4, lambda = 0.5; end
    if nargin < 5, NB = 10; end

    [N, D] = size(X);
    
    % --- 1. 初始化参数 ---
    W = ones(N, 1) / N;    % 初始化样本权重为均匀分布 (Eq. 2)
    H_cell = cell(1, T);   % 存储每一轮的隶属度矩阵 H^t
    alpha_weights = zeros(1, T);   % 存储每一轮的分区权重 alpha_t
    
    % 预计算局部缩放因子 sigma (点到第 NB 个最近邻的距离)
    [~, dists] = knnsearch(X, X, 'K', NB + 1);
    sigma = dists(:, NB + 1); % [N x 1]
    
    % --- 2. 算法 1 迭代过程 ---
    for t = 1:T
        % ==========================================
        % 步骤 A: 真正的两阶段混合采样 (Two-Stage Hybrid Sampling)
        % ==========================================
        % 阶段 1 (Bagging 风格): 从原始数据中均匀有放回地抽取 N 个样本，形成候选集
        idx_candidate = randsample(N, N, true); 
        
        % 阶段 2 (Boosting 风格): 根据样本当前的权重 W，从候选集中再次抽取 N 个样本
        % 注意：需要提取候选集中样本的权重，并重新归一化
        W_candidate = W(idx_candidate);
        W_candidate = W_candidate / sum(W_candidate);
        
        % 在候选集内部进行带权重的二次抽样的索引
        idx_secondary = randsample(N, N, true, W_candidate); 
        
        % 映射回原始数据集的真实索引
        idx_final_sample = idx_candidate(idx_secondary);
        X_sub = X(idx_final_sample, :);
        
        % ==========================================
        % 步骤 B: 在采样集上生成基聚类
        % ==========================================
        % 对采样后的子集运行 K-means
        [sub_labels, centers] = kmeans(X_sub, k, 'EmptyAction', 'singleton');
        
        % ==========================================
        % 步骤 C: 计算全局与局部构成的隶属度矩阵 H^t (Eq. 8)
        % ==========================================
        dist_mat = pdist2(X, centers); % 计算全体数据到聚类中心的距离 [N x k]
        Ht = zeros(N, k);
        
        for j = 1:k
            % 找到当前簇 j 在子样本集中的索引
            in_cluster_idx = (sub_labels == j);
            
            % 计算第 j 个簇的平均局部密度 (sigma_j_avg)
            if sum(in_cluster_idx) > 0
                sigma_j_avg = mean(sigma(idx_final_sample(in_cluster_idx)));
            else
                sigma_j_avg = mean(sigma); % 防止空簇引发的 NaN
            end
            
            % 计算隶属度
            Ht(:, j) = exp(-(dist_mat(:, j).^2) ./ (2 * sigma .* sigma_j_avg + eps));
        end
        
        % 归一化 Ht 的每一行，使其和为 1
        Ht = Ht ./ (sum(Ht, 2) + eps);
        H_cell{t} = Ht;
        
        % ==========================================
        % 步骤 D: 计算指数损失与更新权重
        % ==========================================
        % 1. 计算每个样本的指数损失 (Eq. 10)
        % l_t(x_n) = 1 - max(H_t(n,:)) + min(H_t(n,:))
        lt = 1 - max(Ht, [], 2) + min(Ht, [], 2);
        
        % 2. 计算分区权重 alpha_t (结合了 Lambda 参数)
        % 严格按照推导公式：alpha = exp( - sum(lt) / (lambda * N) )
        alpha_weights(t) = exp(-sum(lt) / (lambda * N));
        
        % 3. 更新样本权重 W (Eq. 13)
        W = W .* exp(alpha_weights(t) * lt);
        W = W / sum(W); % 严格归一化
    end
    
    % --- 3. 共识函数 (Consensus Function) ---
    % 构造加权特征表示 (Section III-B)
    % H_tilde = [sqrt(alpha_1)H^1, ..., sqrt(alpha_T)H^T]
    H_final = zeros(N, T * k);
    for t = 1:T
        start_col = (t - 1) * k + 1;
        end_col = t * k;
        H_final(:, start_col:end_col) = sqrt(alpha_weights(t)) * H_cell{t};
    end
    
    % 在 H_final (加权隶属度矩阵) 上运行最终 K-means 以获得共识分区
    consensus_partition = kmeans(H_final, k, 'MaxIter', 500, 'Replicates', 10);
end