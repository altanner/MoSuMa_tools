#!/bin/bash
# A script for automating the MoSuMa tools pipeline,
# Al Tanner November 2016
# USAGE: run the script from a folder containing fasta files,
# and nothing else.
# USAGE: sh matrix_compiler.sh [absolute path to blast target file]
#need to automate blast target file

if [ $# -eq 0 ]
  then
    echo "matrix_compiler.sh :: USAGE"
    echo "Please provide the absolute path to your blast target file. for example:"
    echo "sh matrix_compiler.sh /home/john/project1/blast_targets"
    exit 1
fi

# make a folder for each file, named after each file and move each into it
echo "Making folders for these files to go in..."
find . -not -path '*/\.*' -type f -not -name '.' -exec sh -c 'mkdir "${1%.*}" ; mv "$1" "${1%.*}" ' _ {} \;

# clean the .fas in each folder
starting_folder=$PWD;
for folder in */; do 
    cd $folder; 
    for file in *; do 
	perl ~/mosuma_dev/fasta_clean_2015.pl $file $file.clean; done; 
    cd $starting_folder; 
done;

# format the clean file in each folder
for folder in */; do 
    cd $folder; 
    for i in *.clean; do 
	formatdb -i $i -p T; 
    done; 
    cd $starting_folder; 
done;

# blast
for folder in */; do 
    cd $folder; 
    for file in *.clean; do 
	perl ~/git/MoSuMa_tools/blast_all_2015.pl $1 $file -aa; done; 
    cd $starting_folder; 
done;

# select the top hits
for folder in */; do 
    cd $folder/blast_out/; 
    perl ~/git/MoSuMa_tools/extract_blast_2015.pl -10 $folder; 
    cd $starting_folder; 
done;

# make an output folder named after the date, one layer up
out_folder=`date +"%d%h%y_%H.%M.%S"`;
mkdir $starting_folder/../$out_folder/;

# put the top selected hit into a file named after the blast target
for folder in */; do 
    cd $folder/blast_out/selected_hits/; 
    for file in *; do 
	head -2 $file >> $starting_folder/../$out_folder/$file; done; 
    cd $starting_folder; 
done;

# rename .sel to .fas in the gene folder
find $starting_folder/../$out_folder -name '*.sel' -exec sh -c 'mv "$0" "${0%.sel}.fas"' {} \;

# remove slashes that might have cropped up in the files
sed -i "s/[/]/_/g" $starting_folder/../$out_folder/*;

# align all of the selected hits to make gene matrices
for file in $starting_folder/../$out_folder/*; do 
    muscle -in $file -out $file.ali; 
done;

# move the aligned MUSCLE output matrices to their own folder
ali=_aligned;
mkdir $starting_folder/../$out_folder$ali;
mv $starting_folder/../$out_folder/*.ali $starting_folder/../$out_folder$ali/;

# rename .fas.ali to .ali in the aligned folder
find $starting_folder/../$out_folder$ali -name '*.fas.ali' -exec sh -c 'mv "$0" "${0%.fas.ali}.ali"' {} \;

# ummmmmmm that should be it
echo "=== matrix_compiler.sh ==="
echo "All done. Aligned gene matrices are in $out_folder$ali."
echo "==========================
