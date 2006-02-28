#!/usr/bin/perl

use YAML;
use Data::Dumper;
use Perl6::Subs;

use strict;
use warnings;

use subs qw/ create_table_sql /;

my $filename = 'database_schema.yaml';

open( my $fh, $filename );
my $yaml_data = join '', <$fh>;
close $fh;

my $db_schema = Load($yaml_data);

print join( "\n\n", create_table_sql($db_schema->{database_tables}) ) . "\n";

sub create_table_sql ( $tables of Hash ) {

    my @bunch_of_sqls;
    for my $table_name ( keys(%$tables) ) {

        my @column_list;
        for my $columns ( $tables->{$table_name} ) {
            for my $column ( @$columns ) {
                my ( $name, $type ) = %$column;
                push @column_list, "$name $type";
            }
        }

        push @bunch_of_sqls, "CREATE TABLE $table_name ("
                             . join( ', ', @column_list ) . ");";
    }

    return @bunch_of_sqls;
}
