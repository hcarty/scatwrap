package ScatWrap::Database::DDAScatteringPlanes;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

# The columns in this table.
my $columns = q/
    id
    parameterid
    phi
    theta_min
    theta_max
    theta_num /;

# Table description.
ScatWrap::DDAScatteringPlanes->table('dda_scattering_planes');
ScatWrap::DDAScatteringPlanes->columns( All => qq/$columns/ );

# Data relationships.
ScatWrap::DDAScatteringPlanes->has_a( parameterid => 'ScatWrap::Database::DDAParameters' );

1;
