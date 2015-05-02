use warnings;
use strict;

my @phyml_files = <*.phy>;
foreach my $phyml_file (@phyml_files) {
    `phyml -i $phyml_file -m LG -d aa -s BEST`;
}

exit;
