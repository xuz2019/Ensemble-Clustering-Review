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
for dataIdx = 50:86
    dataIdx
    dataPath = getDataName('../datasets', dataIdx)
    % dataPath = 'seed'
    load(['../datasets/', dataPath]);
    
    n = length(gt);
    k = length(unique(gt));

    mean_result1 = [];
    std_result1 = [];
    
    parfor idx = 1:cntTimes
        clusterings = members;
        [bcs, baseClsSegs] = getAllSegs(clusterings);
        [results1] = main(baseClsSegs', M, k);
        measure1(:, idx) = computeMetrics(results1', gt);
    end
    
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