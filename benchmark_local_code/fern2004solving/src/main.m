function [final_labels] = main(clusterings, M, K)
% clusterings: 输入的集成成员矩阵，大小为 n x M
% M: 集成规模（即基聚类器的数量）
% K: 最终期望的目标聚类数目

[n, ~] = size(clusterings);

%% 1. 构造连接矩阵 A (Connectivity Matrix)
% 矩阵 A 的行对应实例，列对应所有的簇 [cite: 427]
% A(i, j) = 1 表示第 i 个实例属于第 j 个簇 [cite: 428]

A = [];
for r = 1:M
    % 获取第 r 次聚类的结果
    current_clustering = clusterings(:, r);
    unique_clusters = unique(current_clustering);
    num_clusters_in_r = length(unique_clusters);
    
    % 构造当前聚类的 one-hot 编码矩阵 (n x num_clusters_in_r)
    temp_A = zeros(n, num_clusters_in_r);
    for j = 1:num_clusters_in_r
        temp_A(current_clustering == unique_clusters(j), j) = 1;
    end
    
    % 将所有聚类的簇按列拼接 [cite: 391, 427]
    A = [A, temp_A];
end

t = size(A, 2); % 总簇数

%% 2. 构造二部图的权重矩阵 W [cite: 426]
% W = [0  A; 
%      A' 0]
% 这是一个 (n+t) x (n+t) 的对称矩阵 [cite: 361, 427]

W = [zeros(n, n), A; 
     A', zeros(t, t)];

%% 3. 谱图划分 (Spectral Partitioning - SPEC) [cite: 476, 479]
% 论文中提到使用 Ng et al. 的算法，优化归一化切 (Normalized Cut) [cite: 479]

% 计算度矩阵 D [cite: 480]
d = sum(W, 2);
% 避免除以 0
d(d == 0) = eps;
D = diag(d);

% 计算归一化拉普拉斯矩阵 L = D^(-1) * W [cite: 482]
% 注意：Ng 等人的标准算法通常使用 L = D^(-1/2) * W * D^(-1/2)
% 此处严格按照论文描述：寻找 L 的 K 个最大特征向量 [cite: 482]
L = D \ W; 

% 获取前 K 个最大特征向量 [cite: 482]
[U, ~] = eigs(sparse(L), K, 'la');

% 行归一化 [cite: 482]
norm_U = sqrt(sum(U.^2, 2));
norm_U(norm_U == 0) = eps;
U_normalized = bsxfun(@rdivide, U, norm_U);

%% 4. 提取实例部分的划分结果 [cite: 436]
% 对嵌入后的点（包括实例和簇）进行 K-means 聚类 [cite: 483, 486]
% 论文指出，HBGF 使得实例和簇同时被嵌入并聚类 [cite: 486]
all_labels = kmeans(U_normalized, K, 'Replicates', 5);

% 只输出前 n 个实例的标签作为最终结果 [cite: 436]
final_labels = all_labels(1:n);

end