#!/bin/bash

# automatically assembles data from a NCBI Short Read Archive
# repository, using Trinity.
# The script will prepare a qsub PBS script and queue it
# on the system job server.
# All records will be assumed to be paired-end reads!!

# if the record isn't given, quit.
if [[ $# -ne 1 ]] ; then
    echo "SRA_2_assembly.sh: what SRA record do you want to retrieve and download?"
    echo "example: SRA_2_assembly.sh SRR1611583"
    exit 1;
fi

# get .sra file from NCBI SRA
cd ~/ncbi/public/sra/
prefetch --max-size 100G $1;

# dump the fastq data from sra file
fastq-dump -split-3 ~/ncbi/public/sra/$1.sra;

# make an assembly directory
mkdir ~/$1_assembly;
cd !$;

# move reads to assembly directory
# and remove spaces, Trinity can't deal with spaces.
mv ~/ncbi/public/sra/$1_* ~/$1_assembly;
perl -lape 's/\s+//sg' ~/$1_assembly/$1_1.fastq > ~/$1_assembly/$1_1.fastq.cln;
perl -lape 's/\s+//sg' ~/$1_assembly/$1_2.fastq > ~/$1_assembly/$1_2.fastq.cln;

# prepare PBS script
echo "#!/bin/bash" > ~/$1_assembly/$1_assembly.pbs;
echo "#PBS -N $1_assembly" >> ~/$1_assembly/$1_assembly.pbs;
echo "#PBS -l walltime=120:00:00,nodes=1:ppn=8" >> ~/$1_assembly/$1_assembly.pbs;
echo "#PBS -q highmem" >> ~/$1_assembly/$1_assembly.pbs;
echo "module load samtools/1.3.1" >> ~/$1_assembly/$1_assembly.pbs;
echo "module load bowtie/1.1.2" >> ~/$1_assembly/$1_assembly.pbs;
echo 'export RUNDIR="/home/at9362/weird_assemblies/Cephalothrix_hongkongiensis' >> ~/$1_assembly/$1_assembly.pbs;
echo 'export APPLICATION="/home/at9362/bin/trinityrnaseq-2.1.1/Trinity"' >> ~/$1_assembly/$1_assembly.pbs;
echo 'export RUNFLAGS=" --seqType fq -max_memory 100G --CPU 8 --min_kmer_cov 1 --left $1_1.fastq.cln --right $1_2.fastq.cln -trimmomatic --SS_lib_type RF --output trinity_out_$1 --full_cleanup"' >> ~/$1_assembly/$1_assembly.pbs;
echo "cd $RUNDIR" >> ~/$1_assembly/$1_assembly.pbs;
echo "$APPLICATION $RUNFLAGS" >> ~/$1_assembly/$1_assembly.pbs;

# submit PBS script
qsub ~/$1_assembly/$1_assembly.pbs;

exit 0;
