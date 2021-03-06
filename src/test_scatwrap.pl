#!/usr/bin/env perl

use Getopt::Long;
use ScatWrap::DDSCAT;
use YAML::Syck qw/Dump Load LoadFile DumpFile/;
use Data::Dumper;

use strict;
use warnings;

# Handle command line arguments, with sane default values usable in testing.
my $input_file  = 'Shapes/HexagonalRosette.obj';
my %scale = (
    x => 1,
    y => 1,
    z => 1,
    uniform => 0,
);
GetOptions( "object-file=s" => \$input_file,
            "scale-x=i" => \$scale{x},
            "scale-y=i" => \$scale{y},
            "scale-z=i" => \$scale{z},
            "scale-uniform=i" => \$scale{uniform},
);

# Uniformly scale all of the axes if requested.
if ( $scale{uniform} ) {
    for ( qw/x y z/ ) {
        $scale{ $_ } = $scale{uniform};
    }
}

# Create the shape object and load the information from disk.
my $shape = ScatWrap::DDSCAT->new( scale      => \%scale );
$shape->load_shape_from_file( $input_file );
$shape->parameters( ( LoadFile('test_parameters.yaml') ) );

# Save the generated dipoles in a DDA-friendly format.
#$shape->to_file( shape_filename => 'test.dat', parameter_filename => 'test.par' );

# Run ddscat on our shiny new dipoles.
$shape->run_ddscat();

$shape->to_database();

print "Done.\n";
