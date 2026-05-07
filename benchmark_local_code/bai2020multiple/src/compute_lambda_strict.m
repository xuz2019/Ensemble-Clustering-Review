function lambda = compute_lambda_strict(baseClsSegs, bcs)
    [N, M] = size(bcs);
    lambda = ones(N, M); 
    % 如果是严格按照 MKM 生成的基聚类，
    % 可信度应由基聚类器直接提供（即落在半径 eps 内的点）。
    % 若没有原始坐标，这里默认全部为 1，或根据类簇大小设置阈值（去噪声）。
end