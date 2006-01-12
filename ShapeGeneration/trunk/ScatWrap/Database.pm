package ScatWrap::Database;

use DBI;
use Perl6::Attributes;
use Perl6::Subs;
use Spiffy -base;

use strict;
use warnings;

use subs qw( new DESTROY _open_db _close_db );

field 'dbh';                # Database handle.
field 'db_filename';        # Database file on disk (XXX: SQLite specific).

# Class constructor -- open the database.
# XXX: Contains SQLite specific code
sub new ( $object_class, $db_filename ) {
    
    my $self = bless( {}, $object_class );
    $.db_filename = $db_filename;

    $self->_open_db();

    return $self;
}

# Class destructor -- make sure we clean up after ourselves.
sub DESTROY ( $self ) {

    ./_close_db();
}

# Open a SQLite database connection.
sub _open_db ( $self ) {

    # XXX: SQLite specific code!
    $.dbh = DBI->connect( "dbi:SQLite:dbname=" . $.db_filename,
                          "", "", { RaiseError => 1 } )
      or die "Unable to open database '$database': " . $DBI::errstr;
}

# Close the database connection.
sub _close_db {

    $.dbh->disconnect();
}

1;
