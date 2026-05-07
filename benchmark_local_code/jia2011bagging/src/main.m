function [final_consensus] = main(clusterings, Num, k)
    % 输入: 
    % clusterings: 预生成的基聚类结果 (n x H 矩阵，H为总个数)
    % Num: 论文中定义的 selected number (预定义的选择子集大小) [cite: 148]
    % k: 聚类簇数 (K)
    
    [n, H] = size(clusterings);
    T = 1; % 论文实验中通常使用的迭代次数 [cite: 184]
    
    % 初始化存储每个成员在T次迭代中的相关性得分 (Rank)
    % 论文公式(1): Rank = 1 - NMI(Pi, P*) [cite: 129]
    all_ranks = zeros(T, H);
    
    % --- Step 1: 通过 Bagging 计算成员排名 (Algorithm 2) ---
    for t = 1:T
        % 1. 随机从 H 个成员中有放回地抽取一半 (H/2) 
        subset_idx = randsample(H, floor(H/2), true);
        sub_clusterings = clusterings(:, subset_idx);
        
        % 2. 结合该子集生成临时共识划分 P* (Con^(k)) [cite: 150]
        % 根据论文 4.2 节，样本量 > 2000 使用 MCLA，否则可用 CSPA/MCLA [cite: 124]
        if n > 2000
            temp_consensus = mcla(sub_clusterings', k); 
        else
            temp_consensus = cspa(sub_clusterings', k); 
        end
        
        % 3. 计算所有原始成员 Pi 与临时共识 P* 的相关性 (Relevance Measure) [cite: 150]
        % 论文使用 1-NMI 或 1-ARI。值越小表示成员与共识越接近(质量越高) [cite: 129, 140]
        for i = 1:H
            % NMI 范围 [0, 1]，1表示完全相同 [cite: 139]
            nmi_val = computeNMI(clusterings(:, i), temp_consensus);
            all_ranks(t, i) = 1 - nmi_val; 
        end
    end
    
    % --- Step 2: 计算平均排名 RC(final) (Algorithm 2 - Step 2) ---
    % 根据论文公式(8)，对 T 次排名的相似度最大化等价于求均值 [cite: 146, 151]
    RC_final = mean(all_ranks, 1);
    
    % --- Step 3: 排序并选择前 Num 个成员 (Algorithm 2 - Step 3 & 4) ---
    % 注意：Rank = 1-NMI，值越小越好，故应按升序排列选取“前Num个”最小的值
    % 论文原文Step 3写的是“descending order”，但其Rank定义是 1-NMI
    % 逻辑上是选取与共识最一致（NMI最大/Rank最小）的成员 [cite: 129, 151]
    [~, sorted_idx] = sort(RC_final, 'ascend'); 
    selected_indices = sorted_idx(1:Num);
    
    % --- Step 4: 最终聚合 (Algorithm 3 - Step 3) ---
    % 使用选定的子集生成最终的共识结果 [cite: 157]
    selected_clusterings = clusterings(:, selected_indices);
    if n > 2000
        final_consensus = mcla(selected_clusterings', k);
    else
        final_consensus = cspa(selected_clusterings', k);
    end
end