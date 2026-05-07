function [labels] = main(clusterings, M, k)
    % clusterings: 基础聚类结果 (N x M), N是样本数, M是集成规模
    % M: 集成规模
    % k: 最终输出的聚类簇数 (K)
    
    [N, ~] = size(clusterings);
    DC = 0.9; % 论文推荐的衰减因子 [cite: 125]

    % --- 步骤 1: 构建原始二值关联矩阵 (BM) ---
    % P 是集成中所有簇的总数
    cluster_labels = cell(M, 1);
    P = 0;
    for m = 1:M
        u = unique(clusterings(:, m));
        cluster_labels{m} = u;
        P = P + length(u);
    end
    
    BM = zeros(N, P);
    col_idx = 1;
    for m = 1:M
        for j = 1:length(cluster_labels{m})
            BM(clusterings(:, m) == cluster_labels{m}(j), col_idx) = 1;
            col_idx = col_idx + 1;
        end
    end

    % --- 步骤 2: WCT 算法计算类间相似度 (sim) ---
    % 计算簇与簇之间的边权重 w_xy (基于样本重叠度) [cite: 71]
    W = zeros(P, P);
    for i = 1:P
        for j = i+1:P
            intersect_val = sum(BM(:, i) & BM(:, j));
            union_val = sum(BM(:, i) | BM(:, j));
            if union_val > 0
                W(i, j) = intersect_val / union_val;
                W(j, i) = W(i, j);
            end
        end
    end

    % 计算 WCT_xy (加权三连通路径) [cite: 78, 80]
    WCT = zeros(P, P);
    for i = 1:P
        for j = i+1:P
            % 寻找共同邻居 k，使得 i-k 和 j-k 都有连接
            neighbors = find(W(i, :) > 0 & W(j, :) > 0);
            if ~isempty(neighbors)
                % WCT_xy^k = min(w_ik, w_jk) [cite: 78]
                WCT(i, j) = sum(min(W(i, neighbors), W(j, neighbors)));
                WCT(j, i) = WCT(i, j);
            end
        end
    end

    % 计算最终相似度 sim(Cx, Cy) [cite: 80]
    WCT_max = max(WCT(:));
    Sim_Clusters = eye(P);
    if WCT_max > 0
        Sim_Clusters = (WCT / WCT_max) * DC;
        Sim_Clusters(logical(eye(P))) = 1; % 自相似度为1
    end

    % --- 步骤 3: 生成精炼矩阵 (RM) ---
    % 根据公式 (3) 
    RM = zeros(N, P);
    col_idx = 0;
    for m = 1:M
        num_clusters_in_m = length(cluster_labels{m});
        current_cols = (col_idx + 1) : (col_idx + num_clusters_in_m);
        
        for n = 1:N
            % 找到样本 n 在当前基聚类 m 中所属的簇
            belong_idx = find(BM(n, current_cols) == 1); 
            actual_col = current_cols(belong_idx);
            
            % RM(xi, cl) = sim(cl, C*(xi))
            RM(n, current_cols) = Sim_Clusters(actual_col, current_cols);
        end
        col_idx = col_idx + num_clusters_in_m;
    end

    % --- 步骤 4: 谱聚类共识函数 (SPEC) ---
    % 构建二分图的邻接矩阵 [cite: 85, 86]
    % 矩阵形状为 (N+P) x (N+P)
    A = [zeros(N, N), RM; RM', zeros(P, P)];
    
    % 使用谱聚类分解 
    % 这里简化使用 MATLAB 自带的 spectralcluster 或手动实现
    % 论文中提到使用 Ng et al. (2002) 的方法
    labels = spectral_partitioning(A, k);
    % 只取前 N 个样本的标签
    labels = labels(1:N);
end

function idx = spectral_partitioning(W, k)
    % 简化的 SPEC 实现 (Ng-Jordan-Weiss 算法) 
    D = diag(sum(W, 2));
    L = D^(-0.5) * W * D^(-0.5);
    [V, ~] = eigs(L, k, 'la'); % 取前 k 个最大特征向量
    % 每一行归一化为单位长度
    Y = V ./ sqrt(sum(V.^2, 2));
    % 对嵌入点进行 K-means
    idx = kmeans(Y, k, 'Replicates', 5);
end