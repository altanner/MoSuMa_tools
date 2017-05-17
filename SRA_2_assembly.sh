#!/bin/bash

# automatically assembles data from a NCBI Short Read Archive
# repository, using Trinity.
# The script will prepare a qsub PBS script and submit it to
# the job queue as a high memory task using 8 processors.
# All records will be assumed to be paired-end reads!!

# if the record isn't given, quit.
if [[ $# -ne 1 ]] ; then
    echo "SRA_2_assembly.sh: what SRA record do you want to retrieve and download?"
    echo "example: SRA_2_assembly.sh SRR1611583"
    exit 1;
fi

# get .sra file from NCBI SRA
#cd $HOME/ncbi/public/sra/
#prefetch --max-size 100G $1;

# dump the fastq data from sra file
#fastq-dump -split-3 $HOME/ncbi/public/sra/$1.sra;

# make an assembly directory
#mkdir $HOME/$1_assembly;
#cd $HOME/$1_assembly;

# move reads to assembly directory
# and remove spaces, Trinity can't deal with spaces.
#mv $HOME/ncbi/public/sra/$1_* $HOME/$1_assembly;
#perl -lape 's/\s+//sg' $HOME/$1_assembly/$1_1.fastq > $HOME/$1_assembly/$1_1.fastq.cln;
#perl -lape 's/\s+//sg' $HOME/$1_assembly/$1_2.fastq > $HOME/$1_assembly/$1_2.fastq.cln;

# prepare PBS script
echo "#!/bin/bash" > $HOME/$1_assembly/$1_assembly.pbs;
echo "#PBS -N $1_assembly" >> $HOME/$1_assembly/$1_assembly.pbs;
echo "#PBS -l walltime=120:00:00,nodes=1:ppn=8" >> $HOME/$1_assembly/$1_assembly.pbs;
echo "#PBS -q highmem" >> $HOME/$1_assembly/$1_assembly.pbs;
echo "module load samtools/1.3.1" >> $HOME/$1_assembly/$1_assembly.pbs;
echo "module load bowtie/1.1.2" >> $HOME/$1_assembly/$1_assembly.pbs;
echo "export RUNDIR='$HOME/$1_assembly'" >> $HOME/$1_assembly/$1_assembly.pbs;
echo "export APPLICATION='$HOME/bin/trinityrnaseq-2.1.1/Trinity'" >> $HOME/$1_assembly/$1_assembly.pbs;
echo "export RUNFLAGS=' --seqType fq -max_memory 100G --CPU 8 --min_kmer_cov 1 --left $1_1.fastq.cln --right $1_2.fastq.cln -trimmomatic --SS_lib_type RF --output trinity_out_$1_assembled --full_cleanup'" >> $HOME/$1_assembly/$1_assembly.pbs;
echo 'cd $RUNDIR' >> $HOME/$1_assembly/$1_assembly.pbs;
echo '$APPLICATION $RUNFLAGS' >> $HOME/$1_assembly/$1_assembly.pbs;

# submit PBS script
qsub $HOME/$1_assembly/$1_assembly.pbs;

exit 0;
