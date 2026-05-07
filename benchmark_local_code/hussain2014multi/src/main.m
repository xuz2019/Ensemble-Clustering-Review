function [final_labels] = main(clusterings, M, k)
    % clusterings: 输入的分区矩阵 (n x M)
    % M: 集成规模
    % k: 目标聚类数目
    
    n = size(clusterings, 1);

    %% 1. 计算基于集群的相似度矩阵 (CBSM)
    fprintf('计算 CBSM...\n');
    CBSM = zeros(n, n);
    for i = 1:M
        % 逻辑：计算每对点在所有分区中被归为同簇的比例 (1 - Hamming Distance)
        adj = bsxfun(@eq, clusterings(:, i), clusterings(:, i)');
        CBSM = CBSM + double(adj);
    end
    CBSM = CBSM / M;

    %% 2. 计算成对不相似度矩阵 (PDM)
    fprintf('计算 PDM...\n');
    D_base = 1 - CBSM; 
    % 对不相似度向量计算余弦相似度，衡量“不相似性分布”
    norm_D = sqrt(sum(D_base.^2, 2));
    % eps 防止除以零导致的 NaN
    PDM = (D_base * D_base') ./ (norm_D * norm_D' + eps);

    %% 3. 计算亲和力矩阵 (AFM)
    fprintf('计算 AFM...\n');
    dist_matrix = 1 - CBSM; 
    c = 0.1; % 缩放因子，可尝试 mean(dist_matrix(:))
    AFM = exp(-(dist_matrix.^2) / c);

    %% 4. 聚合矩阵与超度量化 (Ultrametric)
    fprintf('矩阵聚合与超度量化...\n');
    S_avg = (CBSM + PDM + AFM) / 3;
    D_avg = 1 - S_avg;
    
    % --- 数据预处理：确保满足 squareform 严格要求 ---
    D_avg = (D_avg + D_avg') / 2;    % 强制对称
    D_avg(1:n+1:end) = 0;           % 强制主对角线为 0
    D_avg(D_avg < 0) = 0;           % 确保无负值
    % ----------------------------------------------

    % 执行超度量化
    D_ultra = convert_to_ultrametric(D_avg);

    %% 5. 最终聚类 (Consensus Clustering)
    fprintf('执行最终共识聚类...\n');
    % 使用 squareform 将矩阵转为向量以适配 linkage
    d_u_vec = squareform(D_ultra, 'tovector');
    
    % 根据论文，在超度量矩阵上进行最终聚类
    Z = linkage(d_u_vec, 'average');
    final_labels = cluster(Z, 'maxclust', k);
end

function D_u = convert_to_ultrametric(D)
    % 核心逻辑：超度量矩阵对应于单联动聚类树中节点合并的高度
    % 此处使用 MATLAB 优化过的 cophenet 函数一次性完成计算，避免循环报错
    
    % 1. 转化为向量形式
    d_vec = squareform(D, 'tovector');
    
    % 2. 执行单联动聚类 (Single Linkage)
    % 这是获得满足 d(i,j) <= max(d(i,k), d(k,j)) 的标准途径
    Z = linkage(d_vec, 'single');
    
    % 3. 计算 Cophenetic 距离
    % 注意：cophenet 在两个输出参数时，第二个参数返回的就是超度量距离向量
    [~, d_u_vec] = cophenet(Z, d_vec);
    
    % 4. 还原为方阵
    D_u = squareform(d_u_vec);
end