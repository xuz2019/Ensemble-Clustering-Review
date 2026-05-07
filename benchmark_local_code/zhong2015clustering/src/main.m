function [final_labels] = main(clusterings, M, k)
    % clusterings: 基础分区矩阵 (N x M)
    % k: 目标聚类数
    [n, ~] = size(clusterings);
    
    % --- 预处理：特征不可见时，生成集成特征 ---
    % 将聚类标签转化为二值向量，作为计算欧氏距离的“特征” [cite: 386, 490]
    [~, X_ensemble] = getAllSegs(clusterings);
    X_ensemble = full(X_ensemble); 
    X_ensemble = X_ensemble'; % N x Total_Clusters

    % --- 第一步 & 第二步：点级细化 (Eq. 11 & 12) --- [cite: 578, 601]
    % 计算 CM' 矩阵
%     fprintf('Step 1: Computing Point-level Refined Matrix (CM''/Eq.11)...\n');
    CM_prime = zeros(n, n);
    for m = 1:M
        partition = clusterings(:, m);
        unique_clusters = unique(partition);
        for l = 1:length(unique_clusters)
            idx = find(partition == unique_clusters(l));
            if length(idx) > 1
                % 计算该簇内点在集成特征空间下的欧氏距离 [cite: 565, 572]
                dist_matrix = pdist2(X_ensemble(idx, :), X_ensemble(idx, :));
                L = max(dist_matrix(:));
                % Eq. 12: I' = 1 - (dist / L) [cite: 601, 604]
                I_prime = (L > 0) * (1 - dist_matrix / (L + eps)) + (L == 0) * ones(length(idx));
                CM_prime(idx, idx) = CM_prime(idx, idx) + I_prime;
            end
        end
    end
    CM_prime = CM_prime / M;

    % --- 第三步：计算簇稳定性 (Eq. 13 & 14) --- [cite: 579, 583]
%     fprintf('Step 3: Calculating Cluster Stability (S/Eq.13)...\n');
    all_S = [];
    S_cell = cell(M, 1);
    for m = 1:M
        partition = clusterings(:, m);
        u_cls = unique(partition);
        stabs = zeros(length(u_cls), 1);
        for l = 1:length(u_cls)
            idx = find(partition == u_cls(l));
            ni = length(idx);
            if ni > 1
                % Eq. 13: 簇内平均相似度 [cite: 579]
                sub_CM = CM_prime(idx, idx);
                stabs(l) = (sum(sub_CM(:)) - n) / (ni * (ni - 1));
            end
            all_S = [all_S; stabs(l)];
        end
        S_cell{m} = stabs;
    end
    % Eq. 14: 归一化稳定性 S' [cite: 583, 584]
    min_S = min(all_S); max_S = max(all_S);
    for m = 1:M
        S_cell{m} = (S_cell{m} - min_S) / (max_S - min_S + eps);
    end

    % --- 第四步：两级细化矩阵 (Eq. 15 & 16) --- [cite: 587, 590]
%     fprintf('Step 4: Generating Two-level Refined Matrix (CM''''/Eq.15)...\n');
    CM_double_prime = zeros(n, n);
    for m = 1:M
        partition = clusterings(:, m);
        u_cls = unique(partition);
        stabs = S_cell{m};
        for l = 1:length(u_cls)
            idx = find(partition == u_cls(l));
            if length(idx) > 1
                dist_matrix = pdist2(X_ensemble(idx, :), X_ensemble(idx, :));
                L = max(dist_matrix(:));
                % Eq. 16: I'' = I' * S' [cite: 590, 593]
                I_double_prime = ((L > 0) * (1 - dist_matrix / (L + eps)) + (L == 0) * ones(length(idx))) * stabs(l);
                CM_double_prime(idx, idx) = CM_double_prime(idx, idx) + I_double_prime;
            end
        end
    end
    W = CM_double_prime / max(CM_double_prime(:)); % 归一化相似度 [cite: 127]

    % --- 第六步：路径转换 (Eq. 17 & 18) --- [cite: 620, 100, 102]
%     fprintf('Step 6: Path-based Transformation (Max-Min Similarity)...\n');
    % 使用 Prim 算法构建最大生成树，以此快速获得两点间的 Max-Min 相似度 [cite: 128]
    W = path_based_transform(W);

    % --- 第七步：谱聚类 (NCUT) --- [cite: 118, 122]
%     fprintf('Step 7: Final Spectral Clustering (NCUT)...\n');
    final_labels = ncut_clustering(W, k);
end

function W_path = path_based_transform(W)
    n = size(W, 1);
    % 将相似度转为距离以便求最小生成树
    Dist = 1 - W; Dist(logical(eye(n))) = 0;
    G = graph(sparse(Dist));
    T = minspantree(G); % 树路径上的最大边即为 minimax 距离 [cite: 100, 128]
    T_adj = adjacency(T, 'weighted');
    W_path = zeros(n, n);
    for i = 1:n
        % 寻找树中唯一路径上的最大权重（即 minimax 距离）
        [~, max_edges] = bfs_tree_search(T_adj, i);
        W_path(i, :) = 1 - max_edges; % 转回相似度 [cite: 102]
    end
end

function [dists, max_edge] = bfs_tree_search(adj, start)
    n = size(adj, 1);
    max_edge = zeros(1, n); visited = false(1, n);
    q = start; visited(start) = true;
    while ~isempty(q)
        u = q(1); q(1) = [];
        [~, v_nodes, weights] = find(adj(u, :));
        for i = 1:length(v_nodes)
            v = v_nodes(i);
            if ~visited(v)
                max_edge(v) = max(max_edge(u), weights(i));
                visited(v) = true; q = [q, v];
            end
        end
    end
    dists = max_edge;
end

function labels = ncut_clustering(W, k)
    D = diag(sum(W, 2));
    L = D - W;
    [V, ~] = eigs(sparse(L), sparse(D), k, 'smallestreal');
    labels = kmeans(V, k, 'Replicates', 20);
end