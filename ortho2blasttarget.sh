#!/bin/bash
#
#############################################
# ortho2blasttarget.sh # Al Tanner Jan 2017 #
#############################################
#
# Looks through fasta files of orthologous groups of sequences,
# and extracts just the fasta files with more than a given number
# of sequences in them. Produces an output file with the single longest
# hit from each of those orthologous fastas, ready for blast operations.
#
# USAGE: bash ortho2blasttarget.sh [minimum number of seqs per orthologous group]
# EXAMPLE: bash ortho2blasttarget.sh 20 (will extract all orthogroups with 20 or more seqs in)
#

minimum_seqs=$1
fasta_suffix=$2
# if there is no argument, quit
if [[ $# -ne 2 ]] ; then
    echo 'ortho2blasttarget.sh: please include the minimum number of sequences per fasta file :)'
    echo 'ortho2blasttarget.sh: please include the suffix of your fasta files :)'
    echo 'example: bash ortho2blastarget.sh 10 fa (will place files with 10 or more seqs in a folder called "10seqs", looking through files suffixed .fa)'
    exit 0
fi
# quit if output directory already exists...
if [ -d "$1seqs" ]; then
    echo "An output folder called $1seqs already exists here. Better not overwrite that... exiting."
    exit 0
fi
echo "Making an output folder called $1seqs."
mkdir $1seqs
# if the file contains more > fasta headers than $1, put it in a folder.
total_fasta_files=`ls -l *$2 | wc -l`
echo "There are $total_fasta_files fasta files here."
echo "Looking for files with a minimum of $1 seqs and copying them into folder $1seqs."
for file in *.fa; do
    seqs=`grep -c ">" $file`;
    if [ $seqs -ge $1 ]; then
	`cp $file $1seqs/`;
    fi
done;
# move into selected seqs folder
echo "Moving into folder $1seqs."
cd $1seqs/
number_of_selected_files=`ls *.fa -l | wc -l`
echo "$number_of_selected_files files had a minimum of $1 sequences."
# convert to phylip so seq is all on one line
echo "Converting $number_of_selected_files files to phylip."
perl ~/git/MoSuMa_tools/fasta2phylip.pl .fa .phy
# remove phylip header crap / shorten names
echo 'Shortening headers.'
for file in *.phy; do 
    awk '{print $(NF-1) " " $NF}' $file > $file.shortnames; 
done
# order by longest to shortest line
echo "Putting longest sequence to top of file."
for file in *.shortnames; do 
    awk '{ print length($0) " " $0; }' $file | sort -r -n | cut -d ' ' -f 2- > $file.ordered; 
done
# extract the top line, the longest hit
echo 'Taking just the longest hit.'
for file in *.ordered; do 
    head -1 $file > $file.onehit; 
done
# remove phylip headers
echo 'Cleaning up redundant phylip headers.'
for file in *.onehit; do 
    cut -d " " -f2- $file > $file.noname; 
done
# remove filename crap
echo 'Cleaning filenames.'
find . -name '*.noname' -exec sh -c 'mv "$0" "${0%.phy.shortnames.ordered.onehit.noname}seq"' {} \;
# rename phylip header with OGnumber, now the filename
echo 'Renaming output.'
for file in *seq; do 
    perl -p -i -e "s/^/$file /" $file; 
done
# remove "seq" from files
for file in *seq; do 
    perl -p -i -e "s/seq//g" $file; 
done
# concatentate into a single file
echo 'Concatenating into single file.'
cat *seq > blast_targets_$1seqs
# cleanup
echo 'Cleaning up temporary files.'
rm *.phy*
rm *seq
echo "Done. Blast targets are in the folder $1seqs."
echo "These are also in a single file called blast_targets$1seqs, in folder $1seqs."
