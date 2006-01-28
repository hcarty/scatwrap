package ScatWrap::Database::DDAResults;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAResults->table('dda_results');
# XXX: Needs: DDAParameters (one), DDAScatteringPlanes (many), DDAResults (one)
ScatWrap::DDAResults->columns( All => qw// ); # XXX: Fix me!
# XXX: FINISH ME!

1;
