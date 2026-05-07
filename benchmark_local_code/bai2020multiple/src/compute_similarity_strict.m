function W = compute_similarity_strict(baseClsSegs)
    % baseClsSegs: nCls x N
    % 计算类簇间的相交样本数
    intersection = full(baseClsSegs * baseClsSegs'); 
    sz = sum(baseClsSegs, 2);
    
    % 使用 Jaccard 相似度模拟空间邻近性
    % 逻辑：若两个基类簇在不同实验中频繁捕获同一批样本，则它们相似度高
    W = intersection ./ (bsxfun(@plus, sz, sz') - intersection + eps);
    W = W - diag(diag(W)); % 对角线置零
end