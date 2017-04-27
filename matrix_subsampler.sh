#!/bin/bash

############################
# matrix_subsampler.sh     #
# by Al Tanner, April 2017 #
############################

# takes a phylip alignment and outputs a new matrix
# randomly subsampled by position, of a designated length.

# usage: matrix_subsampler.sh [file name] [length of output matrix]
# example: matrix_subsampler.sh arthropods.phy 1000
# this will make a new matrix of random positions, 1000 long
# called "sub1000_arthropods.phy"

# if there are not 2 arguments, quit
if [[ $# -ne 2 ]] ; then
    echo 'matrix_subsampler.sh: please include the matrix you wish to subsample :)'
    echo 'matrix_subsampler.sh: please include the length of the ouput matrix :)'
    echo 'example: bash matrix_subsampler.sh arthropods.phy 1000'
    exit 0
fi

# remove any empty lines
sed '/^\s*$/d' $1 > $1_no_empty_lines;

# remove phylip metadata and sequence headers, so we have just matrix block.
tail -n +2 $1_no_empty_lines > $1_no_header;
awk '{print $NF}' $1_no_header > $1_seqs;
awk '{print $1}' $1_no_header > $1_heads;

# transpose block so we can randomise by rows
awk -F "" '{
for (f = 1; f <= NF; f++)
a[NR, f] = $f
}
NF > nf { nf = NF }
END {
for (f = 1; f <= nf; f++)
for (r = 1; r <= NR; r++)
printf a[r, f] (r==NR ? RS : FS)
}' $1_seqs > $1_seqs_transposed;

# randomise by rows
shuf $1_seqs_transposed > $1_seqs_trans_random;

# undo the transpose
awk -F "" '{
for (f = 1; f <= NF; f++)
a[NR, f] = $f
}
NF > nf { nf = NF }
END {
for (f = 1; f <= nf; f++)
for (r = 1; r <= NR; r++)
printf a[r, f] (r==NR ? RS : FS)
}' $1_seqs_trans_random > $1_seqs_random;

# cut the randomised block to the requested length
cut -c 1-$2 < $1_seqs_random > $1_seqs_random_trimmed;

# reattach sequence headers
paste -d " " $1_heads $1_seqs_random_trimmed > $1_rand_block_no_phylip_metadata;

# reattach phylip metadata header and merge
taxa=`wc -l < $1_seqs`;
echo "$taxa $2" > sub$2_$1;
cat $1_rand_block_no_phylip_metadata >> sub$2_$1;
echo "matrix_subsampler.sh: ok done."
echo "Matrix $1 has been randomly subsampled by $2 positions, output: sub$2_$1"

# cleanup
rm $1_no_empty_lines;
rm $1_no_header;
rm $1_seqs;
rm $1_heads;
rm $1_seqs_transposed;
rm $1_seqs_trans_random;
rm $1_seqs_random;
rm $1_seqs_random_trimmed;
rm $1_rand_block_no_phylip_metadata;
