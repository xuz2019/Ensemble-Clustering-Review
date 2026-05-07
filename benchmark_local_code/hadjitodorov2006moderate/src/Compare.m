clc;clear;
addpath(genpath(pwd)); 
addpath('../utils/');
addpath('../metric/');

rng(2026)

M = 20;
cntTimes = 10;

poolSize = 100;
bcIdx = initialRandom(poolSize, M, cntTimes);

% imcomplete datasets index =
for dataIdx = 1:86
    dataIdx
    dataPath = getDataName('../datasets', dataIdx)
    % dataPath = 'seed'
    load(['../datasets/', dataPath]);
    
    n = length(gt);
    k = length(unique(gt));

    measure1 = zeros(4, cntTimes);
    mean_result1 = [];
    std_result1 = [];
    all_results = cell(cntTimes, 1);
    diversity_scores = zeros(cntTimes, 1);
    
    parfor idx = 1:cntTimes
        clusterings = members(:, bcIdx(idx, :));
        [results1, D_np3] = main(clusterings, M, k);
        all_results{idx} = results1;
        diversity_scores(idx) = D_np3;
    end
    
    % --- 论文核心步骤：中等多样性选择 (Median Selection) ---
    [~, sortedIdx] = sort(diversity_scores);
    medianIdx = sortedIdx(round(cntTimes / 2)); % 取排序后中间位置的索引
    
    best_results = all_results{medianIdx};
    final_diversity = diversity_scores(medianIdx);
    
    % 计算最终指标
    measure1 = computeMetrics(best_results, gt);
    
    mean_measure1 = mean(measure1, 2)';
    std_measure1 = std(measure1, 0, 2)';
    mean_result1 = [mean_result1; [mean_measure1]];
    std_result1 = [std_result1; [std_measure1]];
    
    fprintf("NMI:%.4f,ARI:%.4f,F1:%.4f,Purity:%.4f\n",mean_measure1);

    [~, Idx1] = max(prod(mean_result1(:,end-7:end),2));
    mean1 = mean_result1(Idx1,:);
    std1 = std_result1(Idx1,:);

    dataName = dataPath(1:end-4);
    if (exist(['./cmpResult/', dataName], 'dir') == 0)
        mkdir(['./cmpResult/', dataName])
    end
    if (exist(['./para/', dataName], 'dir') == 0)
        mkdir(['./para/', dataName])
    end

    save(['./cmpResult/', dataName, '/mean1'], "mean1");
    save(['./cmpResult/', dataName, '/std1'], "std1");
    save(['./para/', dataName, '/mean_result1'], "mean_result1");
    save(['./para/', dataName, '/std_result1'], "std_result1");

end