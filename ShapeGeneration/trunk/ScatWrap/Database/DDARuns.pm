package ScatWrap::Database::DDARuns;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDARuns->table('dda_scattering_runs');
ScatWrap::DDARuns->columns( All => qw// );

1;
