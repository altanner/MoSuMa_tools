# Al T, March 2015
# removes troublesome characters from fasta headers
# and shortens fasta titles.
# This avoids most problems further down the chain.

use warnings;
use strict;

if (! $ARGV[1]) {
    print "===\nPlease specify the input file and the what you would like to call the output file.\n";
    print "To trim fasta headers, add the header length as the final argument.\n";
    print "For example: perl fasta_clean.pl wombat.fas wombat.cln 20\n";
    die "will clean wombat.fas and trim headers to 20 characters.\n===\n";
}

my $infile = $ARGV[0];
my $outfile = $ARGV[1];
my $length = $ARGV[2];

if (! -e "$infile") {
    die "===\nThe input file \"$infile\" doesn't seem to exist here...\n===\n";
}

if (-e "$outfile") {
    die "===\nThe output file \"$outfile\" already exists. I don't want to overwrite $outfile. Aborting...\n===\n";
}

`cp $infile $outfile`;

# I'm using "~" as a delimiter to make this more readable...
# Executing on the command line is quicker than reading the whole file...
# (but then I am a rubbish coder... sorry this bit is clumsy.)

print "===\nCleaning...";
`perl -p -i -e "s~[ ]|\t|\/|-|\\|~~g" $outfile`;
if ($ARGV[2]) {
    print " Shortening headers to $length characters...";
    `sed -i '/>/s/^\\(.\\{$length\\}\\).*/\\1/g' $outfile`;
}

print "\nOK done. $infile cleaned and written to $outfile\n===\n";

exit;
