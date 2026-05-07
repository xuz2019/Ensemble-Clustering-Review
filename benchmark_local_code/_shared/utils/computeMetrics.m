function measure = computeMetrics(result, gt)
    NMI = compute_nmi(result, gt);
    ARI = RandIndex(result, gt);
    [F, Precision, Recall] = compute_f(result, gt);
    Purity = compute_purity(result, gt);
    ACC = compute_acc(result, gt);
    Kappa = compute_kappa(result, gt);
    measure = [NMI, ARI, F, Purity, ACC, Kappa, Precision, Recall]';
end

