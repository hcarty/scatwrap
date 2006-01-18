package ScatWrap::Database::DDAParameters;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAParameters->table('dda_parameters');
ScatWrap::DDAParameters->columns( All => qw// ); #XXX: FIX ME!

1;
