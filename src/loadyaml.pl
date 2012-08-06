#!/usr/bin/perl -w

use YAML;
use Data::Dumper;

use strict;

my $settings = {
    database_tables => {
        dda_parameters => [
            { name          => 'VARCHAR(64)' },
            { description   => 'VARCHAR(64)' }
        ],
        dda_result => [
            { foo1      => 'INTEGER' },
            { foo2      => 'TEXT'    }
        ]
    }
};

open( YAMLFILE, 'settings.yaml' ) or die "$!";

print Dump($settings);

$settings = Load( join( '', <YAMLFILE> ) );

print Dump($settings);

close(YAMLFILE);
