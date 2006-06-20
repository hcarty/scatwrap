package Wiki::IO;

use Moose;
use DBI;
use SQL::Abstract;
use Carp;
use strict;
use warnings;

# XXX: These should probably be moved elsewhere, and either loaded from disk or some other method.
my $WIKI_DBI_SOURCE = 'dbi:SQLite:dbname=wiki.db';
my $WIKI_DBI_ATTRIBUTES = {
    RaiseError => 1,
    AutoCommit => 1,
};

has 'dbh' => (
    isa => 'Ref',
    is => 'ro',
    default => sub { DBI->connect( $WIKI_DBI_SOURCE, '', '', $WIKI_DBI_ATTRIBUTES ) }
);
has 'sql_gen' => (
    isa => 'Ref',
    is => 'ro',
    default => sub { SQL::Abstract->new() }
);

sub save {

    my ( $self, $data_table, $data ) = @_;

# Generate the SQL statement
    my ( $statement, @data ) = $self->sql_gen->insert( $data_table, $data );

# Prepare the statement with the database, and apply the change
    my $statement_handle = $self->dbh->prepare($statement);
    $statement_handle->execute(@data);
}

sub load {

# XXX: Arguments: data_table to retrieve from,
#                 array ref containing the fields to load,
#                 hash ref containing the restrictions (where foo = 1, etc),
#                 array ref containing the fields to order by in order of precendence
# XXX: Returns: The data as it comes from DBI (specifically selectall_arrayref)
    my ( $self, $data_table, $data, $where, $order ) = @_;

# Generate the SQL statement
    my ( $statement, @data ) = $self->sql_gen->select( $data_table, $data, $where, $order );

# Prepare the statement with the database, and get the data
    return $self->dbh->selectall_arrayref( $statement, undef, @data );
}

1;

# TODO: Write REAL documentation.
# This module provides VERY basic database IO.  Just saving data, and reading
# it.  Someone else has to do the dirty work of figuring out WHAT and WHERE to
# write it.
=head1 dbh
A database handle must be passed to the Wiki::IO constructor.
=cut
=head1 save
Description:
Save the provided data.

Arguments:
1. Table name (probably a page id) - MUST BE LEGITIMATE FOR USE AS A SQL TABLE NAME
2. Hashref of fields => values.
=cut
