package ScatWrap::Display;

use strict;
use warnings;

sub display_vertices {

    my $gnuplot = 'env gnuplot';
    open( GNUPLOT, "|$gnuplot" )
      || die "Unable to open pipe for $gnuplot output: $!";
    close(GNUPLOT);

    print "You should use gnuplot for your visualization!\n";
}

1;
