package ScatWrap::Database::DDARuns;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

# The columns in this table.
my $columns = q//;

ScatWrap::DDARuns->table('dda_scattering_runs');
ScatWrap::DDARuns->columns( All => qq/$columns/ );

1;
