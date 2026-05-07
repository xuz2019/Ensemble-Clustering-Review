function [final_labels] = main(data, M, k)
    % 输入: 
    %   data - 原始特征矩阵 (N x d)
    %   M    - 集成规模 (B)
    %   k    - 聚类数目
    
    [N, ~] = size(data);
    alpha = 0.3; % 论文 Section 4.3 推荐的衰减系数
    
    % 1. 初始化采样概率 P (每个点初始权重相等)
    p = ones(N, 1) / N;
    
    % 2. 预设参考分区 (Reference Partition)
    % 论文 Algorithm 5 第一步：通过对全量数据做一次聚类作为对齐基准
    ref_partition = kmeans(data, k, 'MaxIter', 500, 'Replicates', 5);
    
    % 存储所有基聚类结果 (N x M)，未采样点标记为 0
    ensemble_labels = zeros(N, M);
    % 协同矩阵 (Co-association Matrix)
    co_matrix = zeros(N, N);
    
    for b = 1:M
        % (a) 采样：根据概率 p 抽取 N 个点（带放回采样）
        % 论文指出：更关注容易出错的点
        idx = randsample(N, N, true, p);
        Xi = data(idx, :);
        
        % (b) 聚类：对子样本进行聚类
        sub_labels = kmeans(Xi, k, 'MaxIter', 200);
        
        % (c) 映射：将子样本标签映射回 N 维向量
        pi_b = zeros(N, 1);
        for j = 1:N
            % 注意：同一轮采样中一个点可能被抽中多次，取最后一次赋值即可
            pi_b(idx(j)) = sub_labels(j);
        end
        
        % (d) 对齐 (Relabeling)：严格按照论文 4.2 节使用匈牙利算法
        % 将当前 pi_b 的标签与参考分区对齐，解决标签随机漂移问题
        pi_b_aligned = hungarian_relabel(pi_b, ref_partition, k);
        ensemble_labels(:, b) = pi_b_aligned;
        
        % (e) 更新协同矩阵 (用于最后一步共识函数)
        % 只有当前轮次中同时被采样的点对才会更新计数
        present_idx = unique(idx);
        for r = 1:length(present_idx)
            u = present_idx(r);
            for c = 1:length(present_idx)
                v = present_idx(c);
                if pi_b(u) == pi_b(v) && pi_b(u) > 0
                    co_matrix(u, v) = co_matrix(u, v) + 1;
                end
            end
        end
        
        % (f) 计算一致性索引 (CI) 并更新概率 p
        % 论文公式 (4) & (5)
        CI = compute_CI(ensemble_labels(:, 1:b));
        
        % p_{t+1} = alpha * p_t + (1 - CI)
        p = alpha * p + (1 - CI);
        p = p / sum(p); % 归一化概率分布
    end
    
    % 3. 共识函数 (Consensus Function)
    % 论文 Section 3.2.1 推荐基于协同矩阵的 Average Linkage (AL)
    % 归一化相似度 (考虑每个点对同时被采样的次数)
    % 为了简化，通常除以 M
    sim_matrix = co_matrix / M;
    dist_matrix = 1 - sim_matrix;
    dist_matrix = (dist_matrix + dist_matrix') / 2; % 对称化
    dist_matrix(1:N+1:end) = 0; % 对角线清零
    
    Z = linkage(squareform(dist_matrix), 'average');
    final_labels = cluster(Z, 'maxclust', k);
end