package ScatWrap::Database::DDAScatteringPlanes;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAResult->table('dda_scattering_planes');
ScatWrap::DDAResult->columns( All => qw// );

1;
