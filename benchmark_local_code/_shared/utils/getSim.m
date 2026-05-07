function simMatrix = getSim(baseClt)
    [N,~] = size(baseClt);
    nCls = max(baseClt);
    baseClsSegs = sparse(baseClt, (1:N)', 1,nCls,N);
    simMatrix = full(baseClsSegs' * baseClsSegs);
end