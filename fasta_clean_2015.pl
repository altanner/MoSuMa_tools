# Al T, March 2015
# removes troublesome characters from fasta headers
# and shortens fasta titles.
# This avoids most problems further down the chain.

use warnings;
use strict;

if (! $ARGV[1]) {
    print "===\nPlease specify the input file and the what you would like to call the output file.\n";
    die "For example: perl fasta_clean.pl wombat.fas wombat.cln\n===\n";
}

#my $length = $ARGV[2];
my $infile = $ARGV[0];
my $outfile = $ARGV[1];

if (! -e "$infile") {
    die "===\nThe input file \"$infile\" doesn't seem to exist here...\n===\n";
}

if (-e "$outfile") {
    die "===\nThe output file \"$outfile\" already exists. I don't want to overwrite $outfile. Aborting...\n===\n";
}

`cp $infile $outfile`;

# I'm using "~" as a delimiter to make this more readable...
# Executing on the command line is quicker than reading the whole file...

print "===\nCleaning...\n";
`perl -p -i -e "s~[ ]|\t|\/|\\|~~g" $outfile`;

#print "Editing headers to $length characters long...\n"; # "\K" disregards the preceding part of the regex
#`perl -p -i -e "s~.{3}\K.*\$~~g if (/^>/)" $outfile`; #works but is backwards
#`perl -p -i -e "s~.{3}\K.*\$~~g if (/^>/)" $outfile`;
#`perl -p -i -e "s/^>[0-9a-f]{40}/>/gi" $outfile`;
#`perl -p -i -e "s~.*\$\K.{4}~~g if (/^>/)" $outfile`;

print "OK done. $infile cleaned and written to $outfile\n===\n";
#print "header editing doesn't work yet. sorry.\n";
exit;
