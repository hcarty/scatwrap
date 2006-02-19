package ScatWrap::Database::DDAScatteringPlanes;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDAScatteringPlanes->table('dda_scattering_planes');
ScatWrap::DDAScatteringPlanes->columns( All => qw// );
#XXX: Is this correct?  Should scattering planes be specific to a parameter
#     set, or should they be shared?
#     If they are specfic, then they can probably be put in the same table as
#     the rest of the parameters.
ScatWrap::DDAScatteringPlanes->has_many( parameterids => 'ScatWrap::Database::DDAParameters' );

1;
