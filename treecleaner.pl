# TREECLEANER by Al Tanner, July 2014.
# Examines NEWICK trees for long branches

use strict;
use warnings;
use Data::Dumper;
use Bio::TreeIO;
use Text::Balanced 'extract_bracketed';
use List::Util qw(sum);

if (! @ARGV) {
    die "TREECLEANER: USAGE: perl treecleaner.pl [tree file in NEWICK format]\n";
}

# open file
open(TREEFILE, "<$ARGV[0]") || die "TREECLEANER: Cannot find $ARGV[0] [$!]\n";  
my $newick = <TREEFILE>; 
close (TREEFILE); 

# clean up newick
chomp $newick;
$newick =~ s/ +//g;
my $warnings = 0;
if ($newick =~ m/\|/) {
    print "\n\n === \nTREECLEANER: WARNING: file contains the symbol \"\|\", I cannot deal with this symbol and have removed it.\n";
    $newick =~ s/\|//g;
    $warnings++;
}

# isolate branch lengths and taxa names
my @branch_lengths = $newick =~ /\d+[\.?\d+]*/g;        # match number, with or without decimal point
my @terminal_branches = $newick =~ /\w+:\d+[\.?\d+]*/g; # match [string] ":" [number, with or without decimal point]
for my $index (reverse 0..$#terminal_branches) {        # clean out bootstrap supports that have been
    if ( $terminal_branches[$index] =~ /^\d/ ) {        # mistaken for taxa names.
        splice(@terminal_branches, $index, 1, ());
    }
}

push (my @clade_search_input, $newick);
my $clade_count = () = $newick =~ /\)/g;                # counts occurance of "(" in tree string.
my $total_clade_count = $clade_count + (scalar (@terminal_branches));

print "\n==========================================================\nTREECLEANER:\n\n";
print "Terminal clade (leaf taxa) count \t " . @terminal_branches . "\n";
print "Multiple-member clade count \t\t $clade_count\n";
print "Total clade count \t\t\t $total_clade_count\n";
print "\nTERMINAL TAXA (" . @terminal_branches . ")\t\tBRANCH LENGTHS\n";
my $taxa;
my $length;
my %taxa_length;
foreach (@terminal_branches) {
    ($taxa, $length) = split (/:/,$_);
    $taxa_length{$taxa} = $length;
}    
print "$_ \t\t\t\t$taxa_length{$_}\n" for (sort keys %taxa_length);

# multiple clades search
my $clade_search_regex = qr/
    (                   # start of bracket 1
    \(                  # match an opening bracket
        (?:
        [^\(\)]++       # one or more brackets, non backtracking
            |
           (?1)         # recurse to bracket 1
        )*
    \)                  # match a closing bracket
    )                   # end of bracket 1
    /x;

$" = "\n\t";

my @multi_clades;
while (@clade_search_input) {
    my $string = shift @clade_search_input;
    my @groups = $string =~ m/$clade_search_regex/g;
    push (@multi_clades, @groups) if @groups;
    unshift @clade_search_input, map { s/^\(//; s/\)$//; $_ } @groups;
}

print "\nMULTIPLE MEMBER CLADES (" . $clade_count . ")\n";
foreach (@multi_clades) {
    s/\(+//;
    s/:.*?,/ + /g;   # replace stuff between : and , with +
    s/\(//g;         # remove other brackets
    s/:.*?\)$//;     # remove closing bracket
    print "$_\n";
}    

#print "\nAll branch lengths:\n";
#foreach (@branch_lengths) {
#    print "$_\n";
#}

my $branch_count;
my $sum_branch_lengths;
my $average_branch_length;
my @lengths_difference;
my $lengths_standard_deviation;
my %clade_branch_length;

# tree statistics                                           
$branch_count = scalar @branch_lengths;
print "\nNumber of branches = $branch_count\n";
foreach (@branch_lengths) {
    $sum_branch_lengths += $_;
}
$average_branch_length = $sum_branch_lengths / $branch_count;
print "Average branch length = $average_branch_length\n";

# generate standard deviation
@lengths_difference = @branch_lengths;
foreach (@lengths_difference) {
    $_ = ($_ - $average_branch_length);
    $_ *= $_;
}
my $differences_summed = sum (@lengths_difference);
$lengths_standard_deviation = sqrt ($differences_summed / $branch_count);
print "Branch length standard deviation = $lengths_standard_deviation\n";

# look for long branches
my $long_branch_count = 0;
foreach my $branch_length (@branch_lengths) {
    if ($branch_length > ($lengths_standard_deviation * 2)) {
	$long_branch_count++;
    }
}
if ($long_branch_count > 0) {
    print "\n$long_branch_count LONG BRANCHES IDENTIFIED IN $ARGV[0]\n";
    my @keys = sort { $taxa_length{$b} <=> $taxa_length{$a} } keys(%taxa_length);
    my @vals = @taxa_length{@keys};
    my $counter1 = 0;
    for (my $i=0; $i < $long_branch_count; $i++) {
	print "$keys[$counter1]\n";
	$counter1++;
    }
}
else {
    print "No long branches detected in $ARGV[0].\n";
}

if ($warnings > 0) {
    print "\nWARNING... please see warnings at top of output ^^^\n";
}
print "========================================================\n\n";

exit;
