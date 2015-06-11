############################################
# node_distance.pl  |  Al Tanner June 2015 #
############################################
# determines the node distance between two taxa on a newick tree.
# USAGE: perl node_distance.pl [tree file in newick format].
# to aid clarity, match delimiters are tildes (~), not forward slashes.

use strict;
use warnings;

if (! @ARGV) {
    die "Usage: perl node_distance.pl [tree file in newick format]. $!\n";
}

my $newick = `head -1 $ARGV[0]`;
if ($newick =~ m~^$~) {
    die "Please ensure the tree string is on the first line of $ARGV[0]. $!\n";
}

print "Newick string:\n";
print "$newick\n";

#
my @terminal_branches = $newick =~ /\w+:\d+[\.?\d+]*/g; # NOT NECESSARY WHEN INSERTED INTO TC
#

my @taxon_list = (sort @terminal_branches); # put into a new array which is separate from treecleaner.
print "Taxa in this string:\n";
foreach (@taxon_list) {
    s~:.*$~~g; # delete stuff which isn't the taxon name.
    print "$_\n";
}
print "\n";


# determine all taxon pair possibilities from the newick string
print "All taxon pairs:\n";
my @taxon_pairs;
my $outer_loop_count = 0;
my $number_of_taxa = scalar (@taxon_list);
my @shifted_list = (sort @taxon_list);
foreach (@taxon_list) { # loops over the "columns" of the matrix
    my $inner_loop_count = 0;
    if ($outer_loop_count == ($number_of_taxa -1)) {
	last;
    }
    push (@shifted_list, $shifted_list[0]);
    shift @shifted_list; # shifts the list so we never pair like-with-like
    foreach (@taxon_list) { # loops over the "rows" of the matrix
	if ($inner_loop_count == ($number_of_taxa - $outer_loop_count - 1)) {
	    last;
	}
	print "$taxon_list[$outer_loop_count] $shifted_list[$inner_loop_count]\n";
	$inner_loop_count++;
    }
    $outer_loop_count++;
}


my @newick_characters = split ('', $newick); # put the tree into an array for each char.
my $open_br_count = 0;
my $close_br_count = 0;
my @bracket_order_array; # this array will contain just the brackets between 2 taxa.
foreach (@newick_characters) {
    if ($_ =~ m~\(~) {
	push (@bracket_order_array, $_);
	$open_br_count++;
    }
    if ($_ =~ m~\)~) {
	push (@bracket_order_array, $_);
	$close_br_count++;
    }
}

# debug counting brackets etc
print "\nDEBUG\n$open_br_count\n$close_br_count\n@bracket_order_array\n";

exit;
