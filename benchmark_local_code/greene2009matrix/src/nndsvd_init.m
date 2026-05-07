function [W, H] = nndsvd_init(A, k)
% 简化版的 NNDSVD 初始化逻辑 [cite: 463]
    [U, S, V] = svds(A, k);
    W = zeros(size(U));
    H = zeros(k, size(V, 1));
    
    W(:,1) = sqrt(S(1,1)) * abs(U(:,1));
    H(1,:) = sqrt(S(1,1)) * abs(V(:,1))';
    
    for i = 2:k
        uu = U(:,i); vv = V(:,i);
        u_plus = max(uu, 0); u_minus = abs(min(uu, 0));
        v_plus = max(vv, 0); v_minus = abs(min(vv, 0));
        
        if norm(u_plus)*norm(v_plus) >= norm(u_minus)*norm(v_minus)
            W(:,i) = sqrt(S(i,i)) * u_plus;
            H(i,:) = sqrt(S(i,i)) * v_plus';
        else
            W(:,i) = sqrt(S(i,i)) * u_minus;
            H(i,:) = sqrt(S(i,i)) * v_minus';
        end
    end
    % 处理可能的零值
    W = W + 0.001; H = H + 0.001;
end