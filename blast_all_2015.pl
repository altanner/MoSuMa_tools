# Modified March 2015 by Al T. Change to deal with nucleotide or protein blast approaches.
# Original by Davide P, April 2013.

# usage: perl script_name name_file_with_sequences_to_blast* basename_of_blast_database (from formatdb)
# *note that the file of sequences to blast has to be in a simple format where in the same line there is sequence name followed by sequence itself (the two are separated by one or more spaces)

use strict; use warnings;

if (! $ARGV[2]) {
    die "blast_all_2015.pl: USAGE: perl blast_all_2015.pl [sequences to blast] [blast database] [database sequence format \(either -aa or -nt\)]\n                 EXAMPLE: perl blast_all_2015.pl sequences.txt Gallo.fas -aa\n";
}

if ($ARGV[2] !~ m/-nt|-NT|-aa|-AA/) {
    die "blast_all_2015.pl: USAGE: perl blast_all_2015.pl [sequences to blast] [blast database] [database sequence format \(either -aa or -nt\)]\n                 EXAMPLE: perl blast_all_2015.pl sequences.txt Gallo.fas -aa\n";
}

my $infile = $ARGV[0];
my $database_base = $ARGV[1];
my %sequences;
my $seq_count = 1;
open (IN, "<$infile") || die "blast_all_2015.pl: I cannot find \"$infile\"\n";

while (<IN>)
{
    print "blast_all_2015.pl: Storing sequence $seq_count\n";
    my $line = $_;
    chomp $line;
    my ($key, $value) = split (/ /, $line);
    $sequences{$key} = $value;
    $seq_count++;
}

my @sequencenames = keys (%sequences);
my $blast_count = 0;
my $sequences_in_database = scalar(@sequencenames);
print "=====\nblast_all_2015.pl: Sequences in database = $sequences_in_database \n=====\n";

# set which blast search version to use
my $database_format = "";
if ($ARGV[2] =~ "-aa|-AA") { # if amino acids, use blastp
    $database_format = "blastp";
}
if ($ARGV[2] =~ "-nt|-NT") { # if nucleotides, use tblastn
    $database_format = "tblastn";
}

foreach my $key (@sequencenames)
{
    $blast_count++;
    print "blast_all_2015.pl: Blasting sequence $blast_count\n";
    open (OUT, ">infile") || die "blast_all_2015.pl: there is a problem opening infile.\n";
    print OUT ">" . $key . "\n";
    print OUT $sequences{$key} . "\n";
    close OUT;

    system ("blastall -p $database_format -d ${database_base} -i infile -o out");
    `mv out blast_out_${key}`; 
    `rm infile`;
}

close IN;

print "=====\nblast_all_2015.pl: Finished, $blast_count blast operations completed.\n";
my @keys2 = keys(%sequences); # check that a random file looks the right length
my $random_key = $keys2[rand(@keys2)];
if (`grep -c "" blast_out_$random_key` < 12) {
    print "blast_all_2015.pl: Are you sure you told me to use the right blast format? \($ARGV[2]\)\n";
    print "blast_all_2015.pl: (I examined a random file \(blast_out_$random_key\) and it doesn't look right...)\n"
}

# clean up by putting things in a folder
`mkdir blast_out`;
`mv blast_out_* blast_out/`;

print "====\n";

exit;
