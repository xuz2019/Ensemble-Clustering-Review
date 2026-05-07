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

    mean_result1 = [];
    std_result1 = [];
    
    alpha_list = 0.50:0.05:0.90;
    beta_list  = 0.50:-0.05:0.10;
    num_params = length(alpha_list);
    % 设定固定的 lambda 和 gamma
    lambda_val = 0.01; 
    gamma_val = 0.8;

    for p_idx = 1:num_params

        alpha = alpha_list(p_idx);
        beta = beta_list(p_idx);

        parfor idx = 1:cntTimes
            clusterings = members(:, bcIdx(idx, :));
            [bcs, baseClsSegs] = getAllSegs(clusterings);
            [results1] = main(baseClsSegs', clusterings, M, k, alpha, beta, lambda_val, gamma_val);
            measure1(:, idx) = computeMetrics(results1, gt);
        end
        
        mean_measure1 = mean(measure1, 2)';
        std_measure1 = std(measure1, 0, 2)';
        mean_result1 = [mean_result1; [p_idx, mean_measure1]];
        std_result1 = [std_result1; [p_idx, std_measure1]];
        
        fprintf("NMI:%.4f,ARI:%.4f,F1:%.4f,Purity:%.4f\n",mean_measure1);
    end

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