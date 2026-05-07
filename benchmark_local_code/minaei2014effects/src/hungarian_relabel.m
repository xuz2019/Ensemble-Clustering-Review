function aligned = hungarian_relabel(target, reference, k)
    % 构造代价矩阵：计算 target 的类 i 与 reference 的类 j 的不匹配数
    cost_mat = zeros(k, k);
    valid_idx = find(target > 0); % 只考虑本轮采样的样本
    
    for i = 1:k
        for j = 1:k
            % 代价 = 属于 target 第 j 类但在 reference 中不属于第 i 类的点数
            cost_mat(i,j) = sum(target(valid_idx) == j & reference(valid_idx) ~= i);
        end
    end
    
    % 使用匈牙利算法寻找最小代价分配 (MATLAB 自带 matchpairs)
    assignment = matchpairs(cost_mat, 1);
    
    aligned = zeros(size(target));
    for p = 1:size(assignment, 1)
        ref_lab = assignment(p, 1);
        tar_lab = assignment(p, 2);
        aligned(target == tar_lab) = ref_lab;
    end
end