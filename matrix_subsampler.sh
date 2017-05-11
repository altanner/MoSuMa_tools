#!/bin/bash

############################
# matrix_subsampler.sh     #
# by Al Tanner, April 2017 #
############################

# takes a phylip alignment and outputs a new matrix
# randomly subsampled by position, of a designated length.

# usage: matrix_subsampler.sh [input file name] [length of output matrix] [output file name]
# example: bash matrix_subsampler.sh arthropods.phy 1000 sub1000_arthropods.phy
# this will make a new matrix of random positions, 1000 long
# called "sub1000_arthropods.phy"

# if there are not 3 arguments, quit                                                                                                                        
if [[ $# -ne 3 ]] ; then
    echo "matrix_subsampler.sh: please include the matrix you wish to subsample, length of output, and name of output file :)";
    echo "example: bash matrix_subsampler.sh arthropods.phy 1000 sub1000_arthropods.phy";
    exit 1;
fi

# check input file exists                                                                                                                                 
if [ ! -f $1 ]; then
    echo "matrix_subsampler.sh: the file $1 doesn't seem to exist... :/"
    exit 1;
fi

# remove any empty lines
sed '/^\s*$/d' $1 > $1_no_empty_lines;

# if the file looks like a fasta, quit
if grep -q ">" $1_no_empty_lines; then
    echo "matrix_subsampler.sh: $1 looks like a fasta file. I can only deal with phylip :/";
    exit 1;
fi

# if it doesn't look like phylip, quit
field_count_per_line=`awk '$0=NF' $1_no_empty_lines`;
for i in $field_count_per_line; do 
    if [[ $i -ne 2 ]] ; then 
	echo "matrix_subsampler.sh: $1 doesn't look like a phylip file. It doesn't have two fields per line... :/";
	exit 1;
    fi
done

# if asking for matrix longer than input, quit
matrix_length=`awk '{print $(NF)}' $1_no_empty_lines | head -1`;
if [[ $2 -gt $matrix_length ]] ; then
    echo "matrix_subsampler.sh: $1 is $matrix_length positions long. I cannot make a matrix longer than the input file... :/";
    exit 1;
fi

# otherwise, start processing
echo 'matrix_subsampler.sh: thinking...';

# remove phylip metadata and sequence headers, so we have just matrix block.
tail -n +2 $1_no_empty_lines > $1_no_header;
awk '{print $NF}' $1_no_header > $1_seqs;
awk '{print $1}' $1_no_header > $1_heads;

# transpose block so we can randomise by lines
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

# randomise by lines
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
echo "$taxa $2" > $3;
cat $1_rand_block_no_phylip_metadata >> $3;
echo "matrix_subsampler.sh: ok done."
echo "Matrix $1 has been randomly subsampled to $2 positions, output: $3"

# report ambiguity content of output matrix
dash_count=`grep -o "-" $1_seqs_random_trimmed | wc -l`;
X_count=`grep -o "X" $1_seqs_random_trimmed | wc -l`;
questionmark_count=`grep -o "?" $1_seqs_random_trimmed | wc -l`;
total_ambiguous_characters=$(($dash_count + $X_count + $questionmark_count));
total_characters=`wc $1_seqs_random_trimmed | awk '{print $3-$1}'`;
percent_ambiguous_characters=$((200*$total_ambiguous_characters/$total_characters % 2 + 100*$total_ambiguous_characters/$total_characters));
echo "Matrix $3 is around $percent_ambiguous_characters% incomplete or ambiguous.";

# cleanup debug files
rm $1_no_empty_lines;
rm $1_no_header;
rm $1_seqs;
rm $1_heads;
rm $1_seqs_transposed;
rm $1_seqs_trans_random;
rm $1_seqs_random;
rm $1_seqs_random_trimmed;
rm $1_rand_block_no_phylip_metadata;

exit 0;
