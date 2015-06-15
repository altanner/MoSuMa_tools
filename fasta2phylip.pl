############################################ 
#         Al Tanner  :  July 2014          #      
# Converts a fasta file into a phylip file #  
############################################

use warnings; use strict;

if (! $ARGV[1]) {
    die "USAGE: perl fasta2phylip.pl [input file suffix] [output file suffix]\nEG: perl fasta2phylip.pl .fas .phy\n";
}

my @fasta_files = <*$ARGV[0]>;
my $counter = 0;

foreach my $fasta_file_name (@fasta_files) {
    if (`grep -c ">" $fasta_file_name` < 1) {
	die "Are you sure these input files are fasta? They don't have many \">\" in them...\n";
    }
    $counter++;
    my $taxa_counter = 0;                      # reset the taxon count
    my $seq_length = 0;                        # reset the length of the sequence
    chomp $fasta_file_name;
    open (FASTA, "<$fasta_file_name") || die "Infile $fasta_file_name not found.";
    my %taxa_seq = ();                         # empty the hash of the previous data
    my $seq_bool = 0;
    my $taxa; my $seq;
    while (<FASTA>) {
        chomp $_;
	if ((/^>/) && ($seq_bool == 0)) {      # find taxa name
	    $taxa_counter++;
	    $seq_bool = 1;                     # note that a taxa has been found
	    $_ =~ s/>//;                       # remove fasta ">"
	    $taxa = $_;                        # store taxa name
	    next;
	}
	if ((! /^>/) && ($seq_bool == 1)) {    # find seqeunces after ">"
	    s/\s|\t//g;
	    $seq .= $_;                        # join seqs on multiple lines
	}
	if ((/^>/) && ($seq_bool == 1)) {      # until new taxa is found,
	    $taxa_seq{$taxa} = $seq;           # store both taxa and joined seqs   
	    $seq_bool = 0;
	    $taxa = ""; $seq = "";             # empty $taxa and $seq
	    redo;                              # redo the while loop to catch the taxa
	}                                      # (seqbool is reset and ready to go again)
    }	
    if ($seq) {                                # store last sequence
	$taxa_seq{$taxa} = $seq;
    }
    
    $seq_length = length ($seq);
    
    close FASTA;
    $fasta_file_name =~ s/$ARGV[0]//;
    my $outfile_name = "$fasta_file_name" . "$ARGV[1]";
    open OUT, (">$outfile_name") || die "There is a problem opening $outfile_name\n";
    print OUT "$taxa_counter $seq_length\n";
    print OUT "$_ $taxa_seq{$_}\n" for (sort keys %taxa_seq);
    print "=== $fasta_file_name converted to $fasta_file_name$ARGV[1] ===\n";
}    
if ($counter == 0) {
    die "There don't seem to be any files suffixed \"$ARGV[0]\" here...\n";
}

print "=== Done. Converted $counter files. ===\n";

exit;
