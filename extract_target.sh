#!/bin/bash

# extract_target.sh
# Al Tanner - May 2017
# outputs fasta records containing a target string

# do some checks etc etc
if [[ $# -ne 2 ]] ; then
    echo "extract_target.sh: please provide an input file and the search target"
    echo "example: SRA_2_assembly.sh some_sequences.fasta ATGTGATAA"
    exit 1;
fi

if [ ! -f $1 ]; then
    echo "extract_target.sh: the file $1 doesn't seem to exist... :/"
    exit 1;
fi

# split the input file into individual fasta records
awk '/^>/{i++};{print > (i".isolated_fas")}' $1;

# delete all files which don't contain the search target
grep -rL $2 *isolated_fas | xargs rm;

# report records
number_of_hits=`ls -l *isolated_fas 2>/dev/null | wc -l`;
echo "OK finished.";
if [[ $number_of_hits == 0 ]] ; then
    echo "No hits found."
    exit 1;
fi

# put all the hits in one file, clean up
cat *isolated_fas > $1.fasta_hits;
rm *isolated_fas;
echo "There were $number_of_hits hits, saved in $1.fasta_hits";

exit 0;
