package ScatWrap::Database::DDAResults;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAResults->table('dda_results');
ScatWrap::DDAResults->columns( All => qw// );
ScatWrap::DDAResults->has_a( parameterid => 'ScatWrap::Database::DDAParameters' );

1;
