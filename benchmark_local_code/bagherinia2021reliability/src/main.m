function [finalLabels] = main(clusterings_input, M, k)
    % clusterings_input: 输入的基聚类集合
    % M: 集成规模
    % k: 目标聚类数
    
    phi = 1.0; % 论文公式(14)中的调节参数
    
    %% 1. 数据预处理：统一转换为模糊隶属度矩阵格式 (Cell of Matrices)
    % 如果输入是矩阵（硬标签），将其转换为模糊隶属度矩阵 (One-hot)
    if ~iscell(clusterings_input)
%         fprintf('检测到硬聚类矩阵，正在转换为模糊隶属度格式...\n');
        N = size(clusterings_input, 1);
        clusterings = cell(M, 1);
        for m = 1:M
            labels = clusterings_input(:, m);
            unique_l = unique(labels);
            num_c = length(unique_l);
            F = zeros(N, num_c);
            for t = 1:num_c
                F(labels == unique_l(t), t) = 1; % 硬聚类是模糊聚类的特例
            end
            clusterings{m} = F;
        end
    else
        clusterings = clusterings_input;
    end
    
    N = size(clusterings{1}, 1);

    %% 2. 计算 RDCI (可靠性指标) - 严格遵循论文公式(6)-(14)
    all_RDCI = cell(M, 1);
    for u = 1:M
        Fu = clusterings{u};
        num_clusters_u = size(Fu, 2);
        all_RDCI{u} = zeros(1, num_clusters_u);
        
        for i = 1:num_clusters_u
            Cui = Fu(:, i);
            total_unreliability = 0;
            
            for v = 1:M
                if u == v, continue; end
                Fv = clusterings{v};
                % 计算簇 Cui 与基聚类 Fv 的不可靠性 (基于 Shannon 熵)
                unr_uv = compute_unreliability(Cui, Fv);
                total_unreliability = total_unreliability + unr_uv;
            end
            
            % 论文公式 (13) & (14)
            avg_unr = total_unreliability / (M - 1);
            all_RDCI{u}(i) = exp(-phi * avg_unr); 
        end
    end

    %% 3. 构建可靠性加权模糊共向矩阵 (RBWFCo) - 论文公式(16)
    % RBWFCo 是 N x N 的相似度矩阵
    RBWFCo = zeros(N, N);
    
    % 为了加速计算，预计算每个基聚类的加权贡献
    weighted_F_sum = zeros(N, N);
    for m = 1:M
        Fm = clusterings{m};
        RDCI_m = all_RDCI{m};
        % 论文公式(16)的核心：sum_{t} RDCI * (membership_i * membership_j)
        % 矩阵写法：F * diag(RDCI) * F'
        weighted_F_sum = weighted_F_sum + (Fm * diag(RDCI_m) * Fm');
    end
    RBWFCo = weighted_F_sum / M;
    
    % 确保对角线为1（自相关）
    RBWFCo = RBWFCo - diag(diag(RBWFCo)) + eye(N);

    %% 4. 共识函数：层次聚类 (Average Linkage)
    % 将相似度转为距离
    distMat = 1 - RBWFCo;
    distMat = max(distMat, 0); 
    distMat = (distMat + distMat') / 2; % 保证对称
    
    % 转化为 pdist 格式
    Y = squareform(distMat, 'tovector');
    Z = linkage(Y, 'average');
    finalLabels = cluster(Z, 'maxclust', k);
end

%% 计算不可靠性的子函数 (公式 6, 12, 13)
function unr = compute_unreliability(Cui, Fv)
    num_v = size(Fv, 2);
    S_uv = zeros(1, num_v);
    
    % 计算 Cui 与 Fv 中每个簇 Cvj 的相似度 (公式 6 & 7)
    sum_Cui = sum(Cui);
    for j = 1:num_v
        Cvj = Fv(:, j);
        sum_Cvj = sum(Cvj);
        % 模糊集相关性 r
        if sum_Cui == 0 || sum_Cvj == 0
            r = 0;
        else
            r = 1 - 0.5 * sum(abs(Cui/sum_Cui - Cvj/sum_Cvj));
        end
        S_uv(j) = (1 + r) / 2;
    end
    
    % 归一化相似度 (公式 12)
    sum_S = sum(S_uv);
    if sum_S == 0
        unr = 0;
    else
        NS = S_uv / sum_S;
        NS(NS <= 0) = 1e-10; % 避免 log(0)
        unr = -sum(NS .* log(NS)); % Shannon 熵
    end
end