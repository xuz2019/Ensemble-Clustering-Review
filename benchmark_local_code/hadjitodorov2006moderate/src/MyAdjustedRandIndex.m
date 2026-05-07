function ari = MyAdjustedRandIndex(p1, p2)
    % 确保输入为列向量
    p1 = p1(:); p2 = p2(:);
    n = length(p1);
    
    % 重新映射标签到 1, 2, ..., K (解决类别数不同和非连续标签问题)
    [~, ~, u1] = unique(p1);
    [~, ~, u2] = unique(p2);
    k1 = max(u1);
    k2 = max(u2);
    
    % 构建列联表 (Contingency Table)
    % Nij 是同时属于 p1 第 i 类和 p2 第 j 类的样本数
    Nij = zeros(k1, k2);
    for i = 1:n
        Nij(u1(i), u2(i)) = Nij(u1(i), u2(i)) + 1;
    end
    
    % 计算 ARI 公式中的各项组合数之和
    % sum(C(n_ij, 2))
    sum_nij = sum(sum(Nij .* (Nij - 1) / 2));
    
    % sum(C(a_i, 2)) 和 sum(C(b_j, 2))
    ai = sum(Nij, 2);
    bj = sum(Nij, 1);
    sum_ai = sum(ai .* (ai - 1) / 2);
    sum_bj = sum(bj .* (bj - 1) / 2);
    
    % 期望值 Expectation
    expected_index = (sum_ai * sum_bj) / (n * (n - 1) / 2);
    
    % 最大值 Max Index
    max_index = 0.5 * (sum_ai + sum_bj);
    
    % 计算 ARI
    den = max_index - expected_index;
    if den == 0
        ari = 0;
    else
        ari = (sum_nij - expected_index) / den;
    end
end