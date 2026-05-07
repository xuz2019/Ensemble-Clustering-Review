function CI = compute_CI(history)
    % 论文公式 (4): CI(x) = (Max_Frequency_of_Label) / (Total_Appearances)
    [N, ~] = size(history);
    CI = zeros(N, 1);
    
    for i = 1:N
        row_labels = history(i, history(i, :) > 0); % 提取该点参与过的所有聚类标签
        if isempty(row_labels)
            CI(i) = 0;
        else
            % 计算出现次数最多的标签频率
            counts = histcounts(row_labels, 1:max(row_labels)+2);
            CI(i) = max(counts) / length(row_labels);
        end
    end
end