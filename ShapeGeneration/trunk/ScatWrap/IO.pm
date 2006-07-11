package ScatWrap::IO;

# TODO: Write REAL documentation.
=head1 ScatWrap::IO
This module provides VERY basic database IO.  Just saving data, and reading
it.  Someone else has to do the dirty work of figuring out WHAT to write and
WHERE to write it.
=cut
=head1 TODO
# TODO: Add proper type checks for the 'dbh' and 'sql_gen' attributes.  See the Moose docs.
=cut

use Moose;
use DBI;
use SQL::Abstract;

use strict;
use warnings;

# XXX: These should probably be moved elsewhere, and either loaded from disk or some other method.
my $DBI_SOURCE = 'dbi:SQLite:dbname=scatwrap.db';
my $DBI_ATTRIBUTES = {
    RaiseError => 1,
    AutoCommit => 0,
};

has 'dbh' => (
    isa => 'Ref',
    is => 'ro',
    default => sub { DBI->connect( $DBI_SOURCE, '', '', $DBI_ATTRIBUTES ) }
);
has 'sql_gen' => (
    isa => 'Ref',
    is => 'ro',
    default => sub { SQL::Abstract->new() }
);

=head1 save
Description:
Save the provided data.

Arguments:
One or more hashrefs, each containing:
1. Table name to save to - MUST BE LEGITIMATE FOR USE AS A SQL TABLE NAME
2. Hashref of fields => values.

Returns:
The id of the last item inserted (generally the AUTOINCREMENT/PRIMARY KEY value).
=cut
sub save {

    my ( $self, $data_table, $data ) = @_;

# Generate the SQL statement
    my ( $statement, @data ) = $self->sql_gen->insert( $data_table, $data );

# This will hold the id of the last inserted item.
    my $last_id;

# Wrap the database work in an eval {} block to catch any potential errors.
    eval {
# Prepare the statement with the database, and apply the change
        my $statement_handle = $self->dbh->prepare($statement);
        $statement_handle->execute(@data);

        $last_id = $self->dbh->last_insert_id('','','','');

# Make the changes to the database.
        $self->dbh->commit;
    };
    if ($@) {
        warn "Database transaction failed: $@";

# Roll back the unsuccessful change(s).
        eval { $self->dbh->rollback };
        if ($@) {
            warn "Database rollback failed: $@";
        }

        die "Freaking out because the database isn't working.";
    }
    else {
# If everything works, return the proper id value.
        return $last_id;
    }
}

=head2 load
Description:
Load information from the database.

Arguments:
1. The data table which contains the information.
2. Array reference containing the fields to load.
3. Hash reference containing the restrictions (where foo = 1, etc) -- XXX: See SQL::Abstract docs.
4. Array reference containing the fields to order by in order of precendence.

Returns:
1. Array reference of hash references containing each result. -- XXX: Spec this.
Example:
    $result = [
        {
            col1 => 'Contents of column 1, 1st entry',
            col2 => 'Contents of column 2, 1st entry',
        },
        {
            col1 => 'Contents of column 1, 2nd entry',
            col2 => 'Contents of column 2, 2nd entry',
        },
    ];
=cut
sub load {

    my ( $self, $data_table, $fields, $where, $order ) = @_;

# Generate the SQL statement
    my ( $statement, @data ) = $self->sql_gen->select( $data_table, $fields, $where, $order );

# Prepare the statement with the database, and get the data
    my $rows = $self->dbh->selectall_arrayref( $statement, undef, @data );

# Go through each row and save the result as a hash with key of column heading => data.
    my @results;
    for my $row ( @$rows ) {
        my %result;
        for ( my $column = 0; $column < scalar @$fields; $column++ ) {
            $result{ $fields->[ $column ] } = $row->[ $column ];
        }
        push @results, \%result;
    }

# Return a reference to the just-built results structure.
    return \@results;
}

1;
