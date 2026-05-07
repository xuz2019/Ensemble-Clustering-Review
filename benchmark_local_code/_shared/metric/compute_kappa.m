function kappa = compute_kappa(result, gt)
    result = bestMap(gt, result);
    confusion_matrix = confusionmat(gt, result);
    total_samples = sum(sum(confusion_matrix));
    actual_agreement = sum(diag(confusion_matrix));
    expected_agreement =(sum(confusion_matrix, 1)*sum(confusion_matrix, 2))/total_samples;
    kappa = (actual_agreement - expected_agreement) / (total_samples - expected_agreement);
end