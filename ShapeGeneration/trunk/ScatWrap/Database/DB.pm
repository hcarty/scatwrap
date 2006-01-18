package ScatWrap::Database::DB;

use base 'Class::DBI';

use strict;
use warnings;

ScatWrap::Database->connection( '', '', '', { RaiseError => 1 } );

1;
