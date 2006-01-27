package ScatWrap::Database::DB;

use base 'Class::DBI';

use strict;
use warnings;

# TODO: Change all of the ScatWrap::Database::* modules so that they load their
#       table schemas from a file on disk - like the existing
#       database_schema.yaml file.
# TODO: Use the database information loaded from disk as well.
ScatWrap::Database->connection( 'dbi:SQLite:dbfile=scatwrap.db', '', '', { RaiseError => 1 } );

1;
