function [best_k] = modelSelection(X, k_range)
% 根据公式 (3), (4) 计算熵指标 s(k) [cite: 491, 492]
    scores = zeros(length(k_range), 1);
    for idx = 1:length(k_range)
        k = k_range(idx);
        % 此处需运行 NMF 得到 P 矩阵
        % P_hat = P ./ sum(P, 2); % 归一化行 [cite: 469]
        % e_j = - (1/log(k)) * sum(P_hat .* log(P_hat)); % 熵公式 [cite: 488]
        % scores(idx) = 1 - mean(e_j); [cite: 491]
    end
    [~, max_idx] = max(scores);
    best_k = k_range(max_idx);
end