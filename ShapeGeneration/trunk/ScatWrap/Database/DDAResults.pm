package ScatWrap::Database::DDAResults;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAResult->table('dda_results');
ScatWrap::DDAResult->columns( All => qw// ); # XXX: Fix me!
# XXX: FINISH ME!

1;
