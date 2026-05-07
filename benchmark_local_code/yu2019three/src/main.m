function [final_labels] = main(X, clusterings, M, k, alpha, beta, lambda, gamma)
    % X: N x D 数据的特征矩阵
    % clusterings: N x M 的基聚类标签矩阵
    % M: 集成成员数量
    % k: 真实的聚类数/目标聚类数
    % alpha, beta: 三支决策阈值
    % lambda: 大小单元划分的比例阈值
    % gamma: 边界域权重因子
    
    N = size(clusterings, 1);
    
    %% 1. 划分聚类单元 (Cluster Units)
    [unique_units, ~, unit_idx] = unique(clusterings, 'rows');
    num_units = size(unique_units, 1);
    
    unit_sizes = zeros(num_units, 1);
    for i = 1:num_units
        unit_sizes(i) = sum(unit_idx == i);
    end
    
    %% 2. 区分大单元 (Big Units) 和小单元 (Small Units)
    is_big_unit = (unit_sizes > lambda * N);
    big_units_idx = find(is_big_unit);
    small_units_idx = find(~is_big_unit);
    
    %% 3. 计算聚类单元之间的关联度矩阵 BUU (Definition 2)
    BUU = zeros(num_units, num_units);
    for i = 1:num_units
        for j = i:num_units
            common_cnt = sum(unique_units(i, :) == unique_units(j, :));
            val = common_cnt / M;
            BUU(i, j) = val;
            BUU(j, i) = val; 
        end
    end
    
    %% 4. 基于大单元构建初始三支类簇
    if isempty(big_units_idx)
        big_units_idx = (1:num_units)';
    end
    
    big_BUU = BUU(big_units_idx, big_units_idx);
    dist_matrix = 1 - big_BUU; 
    dist_matrix = dist_matrix - diag(diag(dist_matrix)); 
    Z = linkage(squareform(dist_matrix), 'average');
    initial_clusters = cluster(Z, 'maxclust', min(k, length(big_units_idx)));
    
    Core = cell(k, 1);
    Fringe = cell(k, 1);
    for i = 1:length(big_units_idx)
        c_label = initial_clusters(i);
        Core{c_label} = [Core{c_label}, big_units_idx(i)];
    end
    
    %% 5. 三支决策处理小单元
    for idx = 1:length(small_units_idx)
        u_z = small_units_idx(idx);
        S = zeros(k, 1);
        for c = 1:k
            core_list = Core{c};
            fringe_list = Fringe{c};
            sum_core = sum(BUU(u_z, core_list));
            sum_fringe = sum(BUU(u_z, fringe_list));
            size_c = length(core_list) + length(fringe_list);
            if size_c > 0
                S(c) = (sum_core + gamma * sum_fringe) / size_c;
            end
        end
        
        if max(S) <= beta
            continue; 
        end
        
        A = find(S >= alpha); 
        B = find(S > beta & S < alpha); 
        
        if length(A) == 1
            Core{A} = [Core{A}, u_z];
        elseif length(A) > 1
            for a_idx = 1:length(A)
                Fringe{A(a_idx)} = [Fringe{A(a_idx)}, u_z];
            end
        elseif ~isempty(B)
            for b_idx = 1:length(B)
                Fringe{B(b_idx)} = [Fringe{B(b_idx)}, u_z];
            end
        end
    end
    
    %% 6. 输出最终的硬划分标签
    final_labels = zeros(N, 1);
    
    for c = 1:k
        for u_idx = 1:length(Core{c})
            u_real_id = Core{c}(u_idx);
            pts = find(unit_idx == u_real_id);
            final_labels(pts) = c;
        end
    end
    
    for c = 1:k
        for u_idx = 1:length(Fringe{c})
            u_real_id = Fringe{c}(u_idx);
            pts = find(unit_idx == u_real_id);
            unassigned = pts(final_labels(pts) == 0);
            final_labels(unassigned) = c;
        end
    end
    
    unassigned_pts = find(final_labels == 0);
    if ~isempty(unassigned_pts)
        if ~isempty(X)
            centers = zeros(k, size(X, 2));
            for c = 1:k
                class_pts = find(final_labels == c);
                if ~isempty(class_pts)
                    centers(c, :) = mean(X(class_pts, :), 1);
                end
            end
            for pt_idx = 1:length(unassigned_pts)
                pt = unassigned_pts(pt_idx);
                dists = sum((centers - X(pt, :)).^2, 2);
                [~, nearest_c] = min(dists);
                final_labels(pt) = nearest_c;
            end
        else
            final_labels(unassigned_pts) = randi(k, length(unassigned_pts), 1);
        end
    end
end