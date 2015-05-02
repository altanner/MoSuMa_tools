############################################
#         Al Tanner  :  July 2014          #
# Converts a phylip file into a fasta file #
############################################

use warnings; use strict;

if (! $ARGV[1]) {
    die "USAGE: perl phylip2fasta.pl [input suffix] [output suffix]\nEG: perl phylip2fasta.pl .phy .fas\n";
}

my @phylip_files = <*$ARGV[0]>;
my $counter = 0;

foreach my $phylip_file_name (@phylip_files) {
    $counter++;
    chomp $phylip_file_name;
    open (PHYLIP, "<$phylip_file_name") || die "Infile $phylip_file_name not found.";
    my %taxa_seq = ();                         # empty the hash of the previous data

    while (<PHYLIP>) {
        chomp $_; 
	if (/^>/) {
	    die "Are you sure these input files are phylip? Some lines start with a \">\"...\n";
	}
	my $taxa = undef; my $seq = undef;     # empty the scalars
        $_ =~ s/^\s+|\s+$//g;                  # remove any leading or trailing whitespace
	next if (! length);                    # ignore any empty lines
	next if (/[0-9].* [0-9].*/);           # ignore the phylip metadata line
	($taxa, $seq) = split (/\t+|\s+/, $_); # split on tabs or spaces
	$taxa_seq{$taxa} = $seq;               # and put the bits into the hash
    }

    close PHYLIP;
    $phylip_file_name =~ s/$ARGV[0]//;
    my $outfile_name = "$phylip_file_name" . "$ARGV[1]";
    open OUT, (">$outfile_name") || die "There is a problem opening $outfile_name\n";
    print OUT ">$_\n$taxa_seq{$_}\n" for (sort keys %taxa_seq);
    print "=== $phylip_file_name converted to $phylip_file_name$ARGV[1] ===\n";
}

if ($counter == 0) {
    die "!!! $counter files with suffix \"$ARGV[0]\" found !!!\n";
}

print "=== Done. Converted $counter files. ===\n";

exit;
