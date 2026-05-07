function [final_labels] = main(clusterings, M, k)
    % clusterings: N x M 的基聚类标签矩阵
    % M: 基聚类个数
    % k: 最终聚类簇数
    
    [N, ~] = size(clusterings);
    
    % --- 阶段 1: 转换数据表示 (严格对应论文中的符号) ---
    % 使用你提供的 getAllSegs 获取全局类簇索引和关联矩阵
    % bcs: N x M, 每个元素是全局唯一的类簇 ID (1 到 nCls)
    % baseClsSegs: nCls x N 的稀疏矩阵 (类簇与样本的隶属关系)
    [bcs, baseClsSegs] = getAllSegs(clusterings);
    nCls = size(baseClsSegs, 1); 

    % --- 阶段 2: 构建相似度矩阵 W (对应论文 Eq. 7) ---
    % 论文公式 7 依赖质心距离和中点密度。
    % 在特征不可见时，我们使用类簇间的共现概率(Co-association)来模拟“密度”
    % 这里 W 是 nCls x nCls 的矩阵
    W = compute_similarity_strict(baseClsSegs);

    % --- 阶段 3: 划分基类簇 (对应论文 3.3 节) ---
    % 使用归一化谱聚类 (NSC) 将 nCls 个基类簇划分为 k 个组
    % cluster_partition: 长度为 nCls 的向量，值在 1~k 之间
    cluster_partition = nsc_strict(W, k);

    % --- 阶段 4: 可信度评估与投票集成 (对应论文 Eq. 11 & 12) ---
    % 论文核心逻辑：只有属于“可信区域”的基聚类标签才参与投票
    % 在特征不可见时，可信度 lambda(i,h) 通常定义为该样本所属类簇的“紧密度”
    % 如果你的基聚类是通过 MKM 产生的，lambda 应该作为输入传入。
    % 如果没有传入，根据论文 Local Hypothesis，我们计算样本与类簇的一致性。
    lambda = compute_lambda_strict(baseClsSegs, bcs);

    % 最终加权投票
    final_labels = zeros(N, 1);
    for i = 1:N
        votes = zeros(k, 1);
        for h = 1:M
            if lambda(i, h) == 1
                g_idx = bcs(i, h); % 该样本在第 h 个基聚类所属的全局类簇索引
                global_label = cluster_partition(g_idx); % 该类簇对应的最终类别
                votes(global_label) = votes(global_label) + 1;
            end
        end
        [~, final_labels(i)] = max(votes);
    end
end