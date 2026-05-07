function acc = compute_acc(result, gt)
    newIdx = bestMap(gt, result);
    acc = mean(gt == newIdx);
end

