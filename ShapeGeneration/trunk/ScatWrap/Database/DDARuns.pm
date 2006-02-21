package ScatWrap::Database::DDARuns;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

# XXX: Is this module a little redundant?  Is there a good way to include it
#      elsewhere?  Perhaps in the DDAResults region?  Or DDAResults could move
#      over here...

# The columns in this table.
my $columns = q/
    id
    name
    description
    parameterid
    resultid
/;

ScatWrap::DDARuns->table('dda_scattering_runs');
ScatWrap::DDARuns->columns( All => qq/$columns/ );

ScatWrap::DDARuns->has_a( parameterid =>
                             'ScatWrap::Database::DDAParameters' );
ScatWrap::DDARuns->has_a( resultid => 'ScatWrap::Database::DDAResults' );

1;
