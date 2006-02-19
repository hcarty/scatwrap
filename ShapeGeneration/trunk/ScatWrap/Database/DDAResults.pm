package ScatWrap::Database::DDAResults;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

# The columns in this table.
my $columns = q//;

ScatWrap::DDAResults->table('dda_results');
ScatWrap::DDAResults->columns( All => qq/$columns/ );
ScatWrap::DDAResults->has_a( parameterid => 'ScatWrap::Database::DDAParameters' );

1;
