#!/bin/bash                                                                                                                                               

# extract_target.sh                                                                                                                                       
# Al Tanner - May 2017                                                                                                                                    
# outputs fasta records containing a target string                                                                                                        
# into isolated files                                                                                                                                     

# if there is no input file or target, quit                                                                                                               
if [[ $# -ne 2 ]] ; then
    echo "extract_target.sh: please provide an input file and the search target"
    echo "example: SRA_2_assembly.sh some_sequences.fasta ATGTGATAA"
    exit 1;
fi

# split the input file into individual fasta records                                                                                                      
awk '/^>/{i++};{print > (i".isolated_fas")}' $1;

# delete all files which don't contain the search target                                                                                                  
grep -rL $2 *isolated_fas | xargs rm;

# report records with                                                                                                                                     
number_of_hits=`ls -l *isolated_fas | wc -l`;
echo "OK finished.";
echo "There were $number_of_hits hits.";

exit 0;
