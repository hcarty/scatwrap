package ScatWrap::Database::DDAScatteringPlanes;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAScatteringPlanes->table('dda_scattering_planes');
ScatWrap::DDAScatteringPlanes->columns( All => qw// );

1;
