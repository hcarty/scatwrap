#!/usr/bin/perl

use YAML qw/Dump LoadFile/;
use Perl6::Subs;

use strict;
use warnings;

my $filename = 'database_schema.yaml';

my $db_schema = LoadFile($filename);

print join( "\n\n", create_table_sql($db_schema->{database_tables}) ) . "\n";

#TODO Add support for foreign key constraints - either through triggers (SQLite) or add just support so that the SQL can be built for other DBs.
sub create_table_sql ( $tables of Hash ) {

    my @bunch_of_sqls;
    for my $table_name ( keys(%$tables) ) {

        my @column_list;
        for my $columns ( $tables->{$table_name} ) {
            for my $column ( @$columns ) {
                my $column_sql = "$column->{name} $column->{type}";

# Handle DEFAULT values for a column.
                if ( defined $column->{default} ) {
                    $column_sql .= " DEFAULT $column->{default}";
                }
# Handle CHECK constraints on the column.
                if ( defined $column->{check} ) {
                    my $check;
                    if ( $column->{check} =~ /,/ ) {
                        my @constraints = split ',', $column->{check};
                        $check .= "IN ('" . join( "','", @constraints ) . "')";
                    }
                    elsif ( $column->{check} =~ /-/ ) {
                        my @constraints = split '-', $column->{check};
                        $check .= "BETWEEN $constraints[0] and $constraints[1]";
                    }
                    elsif ( defined $column->{check} ) {
                        die "Badly formed check constraint information:\n$column->{check}\non $column->{name} in table $table_name";
                    }
                    if ( $check ) {
                        $column_sql .= " CHECK ($column->{name} $check)";
                    }
                }
                push @column_list, $column_sql;
            }
        }

        push @bunch_of_sqls, "CREATE TABLE $table_name ("
                             . join( ', ', @column_list ) . ");";
    }

    return @bunch_of_sqls;
}
