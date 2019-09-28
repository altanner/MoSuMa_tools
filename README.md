# MoSuMa_tools
A perl script pipeline for the compilation of Molecular SuperMatrices.

***NB: for reasons not understood or resolved, treecleaner.pl should be treated with the utmost caution. In my experience, it seems to work on trees with up to around 60 OTUs. Beyond that, and it becomes unpredictable. I have not understood why, and I am afraid I don't have the time to look into it and fix it. But please feel free to fork and pull-request.***

Currently, this pipeline deals with two input files: a list of genes (or other sequence data) as BLAST targets, and an assembled transcriptome in which to carry out the BLAST search. Data can be in amino acids or nucleotides. Outputs are aligned matrices for each sequence, ready for concatenation into a supermatrix, gene-tree analysis, or anything else really. The treecleaner.pl script will assess a tree created by phyml for long branches, and remove the seqeunce producing the long branch from the gene matrix.

Please post all bugs or other issues in the issues section of the github page (https://github.com/altanner/MoSuMa_tools/) or contact the repo owner (altanner@github) . Thanks :)
