function aproxK = MyNystrom(kernel, N, c)
    kernel = kernel + 0.01 * eye(N);
    kernel = kernel ./ max(max(kernel));

    idx = randperm(N, c);
    Kc = kernel(idx, idx);
    KNc = kernel(:, idx);
    aproxK = KNc / (Kc) * KNc';
    aproxK = (aproxK + aproxK') / 2;
    aproxK = aproxK - min(min(aproxK));
    aproxK = aproxK ./ max(max(aproxK));
    aproxK = aproxK - diag(diag(aproxK)) + eye(N);
end

