##########################################################################
# extract_blast_2015.pl, Al Tanner, March 2015 rev Dec 2015
# counts the number of high hits (the number of evalue = 0.0 hits,
# or the highest hit plus any other hits within 3 orders of magnitude)
# then extracts that many results from the blast output file,
# and places them in a fasta formatted output file.
##########################################################################

use strict;
use warnings;
use Data::Dumper;
use List::Util qw(max);

my @files = <blast_out*>;
my $counter = 0;
my $logfile = "extract_blast.log";
my $hash_size = 0;

if (! $ARGV[1]) {
    print "  USAGE: perl extract_blast_2015.pl [e-value cut-off] [taxon name]\n";
    die "EXAMPLE: perl extract_blast_2015.pl -10 Gallus (only evalues smaller than e-10 will be accepted, faster headers will be named \">Gallus\")\n";
}

###################
# set cut off value
$ARGV[0] =~ s/-//;
my $cut_off = $ARGV[0];

################
# set taxon name
my $taxon_name = $ARGV[1];

open (LOGFILE, ">$logfile") || die "Problem opening logfile...\n";

`mkdir selected_hits/`; # make the output folder        

#########################################################################
# loop over blast_out files and recovers the e-values from the hits table
foreach my $infile (@files) {
    $counter++;
    print LOGFILE "=== Reading file number $counter :: $infile ===" . "\n";
    my %seqs;
    my $evalue_zero = 0;
    my $bool = 0;
    open (IN, "<$infile") || die "Problem opening $infile";
    while (<IN>) {
	chomp;
	if ($_ =~ /^Sequences producing/) { # the table starts with this string
	    $bool = 1;
	}
	if (($_ =~ /^>/) && ($bool == 1)) { # the table ends when a line starts with ">"
	    $bool = 0;
	}
	if (($_ =~ /^\w/) && ($bool == 1)) {
	    my ($name, $bits, $evalue) = split (/[ ]+/, $_); # THIS MIGHT NOT WORK IF THERE ARE SPACES IN THE TITLE
	    $seqs{$name} = $evalue;
	}
    }	

    my %edited_seqs;
    my @keys = keys (%seqs);
	    
###################################################################
# this loop standardises 0.0 to 999 and removes crap around evalue.
# and zero pads to three figures (makes comparisons easier). 
    foreach my $key (@keys) {
	if ($seqs{$key} =~  /^0.0$/) {
	    $edited_seqs{$key} = 999;
	    $evalue_zero = 1;
	    next;
	}
	if (! ($seqs{$key} =~ /e-/)) {
	    next;
	}
	if ($seqs{$key} =~ /e-/) {
	    my $local_var = $seqs{$key};
	    $local_var =~ s/[\d]*e-//;
	    $local_var = sprintf("%03d", $local_var);
	    print LOGFILE "E-value exponent = $local_var \n";
	    $edited_seqs{$key} = $local_var;
	    next;
	}
    } 
# here we need to add reference to arvg, and have subroutine for 
# taking the top value and taking the 3 top values.    
    ########################################################
    # find highest value, and remove evalues not within 10^3
    if (! %edited_seqs) {
	print LOGFILE "No acceptably high hits: all e-values really rubbish (not expressed as exponents).\n";
	print LOGFILE "=== File number $counter done ===" . "\n\n";
	next;
    }
    else {
	my $max = max(values(%edited_seqs));
	if ($max < $cut_off) {
	    %edited_seqs = (); # remove all hits, if they are are not over cut-off
	    print LOGFILE "No acceptably high hits: nothing smaller than cut_off (e-$cut_off)\n";
	}
	print LOGFILE "Best hit = $max (cut-off = e-$cut_off) \n";
	foreach my $key (keys %edited_seqs) {
	    if ($max - ($edited_seqs{$key}) > 3) { # delete any values more than 3
		delete ($edited_seqs{$key});       # orders of magnitude beyond high hit
	    }
	}
    }
    $hash_size = keys %edited_seqs; # how many hits did you keep? (often 1)
    print LOGFILE "$hash_size highest hit(s).\n";
    if ($evalue_zero == 1) {
	print LOGFILE "These are 0.0 e-value hits.\n";
    }

    if ($hash_size > 0) { # if the hits have already been counted, extract stuff
	&extract ($infile, $hash_size, $taxon_name);
    }

    close IN;
    print LOGFILE "=== File number $counter done ===" . "\n\n";
}

`mv extract_blast.log ..`;
print "===\nextract_blast_2015.pl: $counter files processed. Details in $logfile\n";
print "extract_blast_2015.pl: Selected sequences saved to selected_hits/*.sel\n===\n";
print LOGFILE "=== $counter files processed. Done. ===" . "\n\n";
close LOGFILE;

exit;

###############
# SUBROUTINES #
###############

sub extract { # puts the best hits into a fasta output file
    my $seq_count = 0;
    my $name = ">" . "$_[2]";
    my $selected_sequence;
    my %name_n_seq = ();
    my $fasta_bool = 0;
    my $extract_bool = 0;
    open (IN, "<$_[0]") || die "Cannot find $_[0]...\n";
    while (<IN>) {
	chomp;
        if ($seq_count > $_[1]) { # only take as many records as there are high hits
            next;
        }
	if ((/^>/) || (/^ Score =/) && ($extract_bool == 1)) {
	    $seq_count ++;
	    $extract_bool = 0;
	    $fasta_bool = 0;
	    $selected_sequence = "";
	}
	if ((/^>/) && ($extract_bool == 0)) {
	    $fasta_bool = 1;
	}
	if ((/^ Score =/) && ($fasta_bool == 1)) {
	    $extract_bool = 1;
	}
        if ((/^Sbjct/) && ($extract_bool == 1)) {
	    my $extracted_sequence = $_;
	    $extracted_sequence =~ s/^Sbjct: [0-9]+//; # remove sbjct and hit line numbers
            $extracted_sequence =~ s/^\s+//; # get rid of opening space, if there is one
	    my @extract_bits = split (/[ ]+/, $extracted_sequence); # avoid ending number
            $selected_sequence = $selected_sequence . $extract_bits[0];
	    my $zero_padded_seq_count = sprintf("%03d", $seq_count);
	    $name_n_seq{$name . $zero_padded_seq_count} = $selected_sequence;
	}
    }
    close IN;
    $_[0] =~ s/^blast_out_//;
    $_[0] .= ".sel";
    open (OUTFILE, ">$_[0]") || die "Cannot open $_[0] \n\n";
    for (sort keys %name_n_seq) {
	print OUTFILE "$_\n$name_n_seq{$_}\n";
    }
    close OUTFILE;
    # clean up by putting selected files in the output folder
    `mv *.sel selected_hits/`;
}
