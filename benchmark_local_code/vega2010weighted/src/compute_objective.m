function obj = compute_objective(P_star, ensemble, weights)
    % 论文 3.3 节：寻找最大化加权核相似度的分区 [cite: 584, 591]
    m = length(weights);
    obj = 0;
    for i = 1:m
        % 使用 wpck_kernel 替代 cal_nmi
        sim = wpck_kernel(P_star, ensemble(:, i)); 
        obj = obj + weights(i) * sim;
    end
end