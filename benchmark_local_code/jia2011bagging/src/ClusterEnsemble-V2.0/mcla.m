% function cl = mcla(cls,k)
%
% DESCRIPTION
%  Performs MCLA for CLUSTER ENSEMBLES
%
% Copyright (c) 1998-2011 by Alexander Strehl

function cl = mcla(cls,k)

disp('CLUSTER ENSEMBLES using MCLA');

if ~exist('k'),
   k = max(max(cls));
end;

[~, n] = size(cls);

disp('mcla: preparing graph for meta-clustering');
clb = clstoclbs(cls);
cl_lab = clcgraph(clb,k,'simbjac');
num_meta_clusters = max(cl_lab);
clb_cum = zeros(num_meta_clusters, n);
for i=1:max(cl_lab),
   matched_clusters = find(cl_lab==i);

   if ~isempty(matched_clusters)
        % 正常计算均值
        clb_cum(i,:) = mean(clb(matched_clusters,:), 1);
    else
        % 论文保护机制：如果出现空簇，填充为0或全局均值，防止 NaN 扩散
        clb_cum(i,:) = 0; 
   end
   
end;
cl = clbtocl(clb_cum);

