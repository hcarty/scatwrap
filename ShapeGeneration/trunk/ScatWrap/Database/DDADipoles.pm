package ScatWrap::Database::DDAShapes;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

# The columns in this table.
my $columns = q/
    id
    name
    description
    data /;

ScatWrap::DDAShapes->table('dda_dipoles');
ScatWrap::DDAShapes->columns( All => qq/$columns/ );
ScatWrap::DDAShapes->has_many( parameterids => 'ScatWrap::Database::DDAParameters' );

1;
