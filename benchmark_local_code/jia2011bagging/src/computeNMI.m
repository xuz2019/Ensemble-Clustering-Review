function nmi = computeNMI(L1, L2)
    % 严格按照论文公式(2)实现，适配 L1 和 L2 类别数不等的情况
    
    % 将标签映射到连续整数空间 (1, 2, ..., k)，防止类别数不等导致的索引问题
    [~, ~, L1] = unique(L1);
    [~, ~, L2] = unique(L2);
    
    n = length(L1);
    k1 = max(L1);
    k2 = max(L2);
    
    % 1. 计算联合概率分布矩阵 (Confusion Matrix)
    % 这里的维度是 k1 x k2，不再受类别数是否相等限制
    confMat = zeros(k1, k2);
    for i = 1:n
        confMat(L1(i), L2(i)) = confMat(L1(i), L2(i)) + 1;
    end
    
    % 2. 计算互信息 (Mutual Information)
    % 分子：sum(n_hl * log( (n*n_hl)/(n_h*n_l) ))
    n_h = sum(confMat, 2); % 每行求和 (L1 各簇的样本数)
    n_l = sum(confMat, 1); % 每列求和 (L2 各簇的样本数)
    
    MI = 0;
    for h = 1:k1
        for l = 1:k2
            if confMat(h, l) > 0
                MI = MI + confMat(h, l) * log2( (n * confMat(h, l)) / (n_h(h) * n_l(l)) );
            end
        end
    end
    
    % 3. 计算熵 (Entropy) - 分母
    H1 = 0;
    for h = 1:k1
        prob1 = n_h(h) / n;
        H1 = H1 - prob1 * log2(prob1);
    end
    
    H2 = 0;
    for l = 1:k2
        prob2 = n_l(l) / n;
        H2 = H2 - prob2 * log2(prob2);
    end
    
    % 4. 计算标准化互信息 (论文公式 2)
    % 注意：由于熵计算公式中的 n 取消掉了，这里分母需对应处理
    % 论文中的公式 2 本质上等价于 MI / sqrt(Entropy1 * Entropy2)
    % 这里我们使用标准的 NMI 定义：
    if H1 == 0 || H2 == 0
        nmi = 0;
    else
        % 将 MI 的单位统一
        nmi = (MI / n) / sqrt(H1 * H2);
    end
end