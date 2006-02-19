package ScatWrap::Database::DDADipoles;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

ScatWrap::DDADipoles->table('dda_dipoles');
ScatWrap::DDADipoles->columns( All => qw// );
ScatWrap::DDADipoles->has_many( parameterids => 'ScatWrap::Database::DDAParameters' );

1;
