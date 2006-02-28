package ScatWrap::Database::DDAShapes;

use base 'ScatWrap::Database::DB';

use strict;
use warnings;

# The columns in this table.
my $columns = q/
    id
    name
    description
    scalex
    scaley
    scalez
    origin
    data /;

# Table description.
ScatWrap::DDAShapes->table('dda_shapes');
ScatWrap::DDAShapes->columns( All => qq/$columns/ );

# Table relationships.
ScatWrap::DDAShapes->has_many( parameterids => 'ScatWrap::Database::DDAParameters' );

1;
