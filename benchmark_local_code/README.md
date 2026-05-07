# Benchmark Local Code Folders

This directory contains code-only folders for benchmark methods that do not currently have an external public code repository linked in the survey README.
Each folder is standardized from the local experiment workspace and excludes datasets, `.mat` data files, result outputs, and logs.

## Layout

- `_shared/`: shared metric and utility code extracted from the local benchmark workspace
- `<citationKey>/`: one method folder per benchmark reference

## Included Methods

- `bai2020multiple`: A multiple k-means clustering ensemble algorithm to find nonlinearly separable clusters (CA Matrix-based methods)
- `greene2009matrix`: A matrix factorization approach for integrating multiple data views (CA Matrix-based methods)
- `hussain2014multi`: Multi-view document clustering via ensemble method (CA Matrix-based methods)
- `iam2010lce`: LCE: a link-based cluster ensemble method for improved gene expression data analysis (CA Matrix-based methods)
- `tao2017ensemble`: From ensemble clustering to multi-view clustering (CA Matrix-based methods)
- `zhong2015clustering`: A clustering ensemble: Two-level-refined co-association matrix with path-based transformation (CA Matrix-based methods)
- `asur2007ensemble`: An ensemble framework for clustering protein-protein interaction networks (Ensemble weighting methods)
- `hadjitodorov2006moderate`: Moderate diversity for better cluster ensembles (Ensemble weighting methods)
- `jia2011bagging`: Bagging-based spectral clustering ensemble selection (Ensemble weighting methods)
- `vega2010weighted`: Weighted partition consensus via kernels (Ensemble weighting methods)
- `yang2015hybrid`: Hybrid sampling-based clustering ensemble with global and local constitutions (Ensemble weighting methods)
- `fern2004solving`: Solving cluster ensemble problems by bipartite graph partitioning (Graph-based methods)
- `ayad2007cumulative`: Cumulative voting consensus method for partitions with variable number of clusters (Probabilistic methods)
- `Topchy2004Mixture`: A mixture model for clustering ensembles (Probabilistic methods)
- `Topchy2005Models`: Clustering ensembles: Models of consensus and weak partitions (Probabilistic methods)
- `wu2014k`: K-means-based consensus clustering: A unified view (Probabilistic methods)
- `hore2009scalable`: A scalable framework for cluster ensembles (Scalable ensemble methods)
- `minaei2014effects`: Effects of resampling method and adaptation on clustering ensemble efficacy (Scalable ensemble methods)
- `yu2019three`: A three-way cluster ensemble approach for large-scale data (Scalable ensemble methods)
- `avogadri2009fuzzy`: Fuzzy ensemble clustering based on random projections for DNA microarray data analysis (Uncertainty-based methods)
- `bagherinia2021reliability`: Reliability-based fuzzy clustering ensemble (Uncertainty-based methods)
- `hu2016hierarchical`: Hierarchical cluster ensemble model based on knowledge granulation (Uncertainty-based methods)
- `li2017multigranulation`: Multigranulation information fusion: A Dempster-Shafer evidence theory-based clustering ensemble method (Uncertainty-based methods)
- `punera2008consensus`: Consensus-based ensembles of soft clusterings (Uncertainty-based methods)
