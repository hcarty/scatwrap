#!/usr/bin/perl

use Getopt::Long;
use ScatWrap::Shape;
use YAML;

use strict;
use warnings;

# Handle command line arguments.
my $input_file  = 'HexagonalRosette.obj';
my %scale = (
    x => 1,
    y => 1,
    z => 1,
);
GetOptions( "object-file=s" => \$input_file,
            "scale-x=i" => \$scale{x},
            "scale-y=i" => \$scale{y},
            "scale-z=i" => \$scale{z} );

my $shape = ScatWrap::Shape->new( input_file => $input_file,
                                  scale      => \%scale );

$shape->save_dda_data('test.dat');

print "Done.\n";

open( YAMLFILE, ">test.yaml" )
  || die "OH NO!  NO YAML! : $!";
print YAMLFILE Dump($shape);
close( YAMLFILE );
