#!/usr/bin/perl

use Getopt::Long;
use ScatWrap::DDSCAT;
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
            "scale-z=i" => \$scale{z}
);

# Create the shape object and load the information from disk.
my $shape = ScatWrap::DDSCAT->new( scale      => \%scale );
$shape->load_shape_from_file( $input_file );

# Save the generated dipoles in a DDA-friendly format.
$shape->save_dda_data( filename => 'test.dat');
$shape->save_to_database();

$shape->set_default_parameters();
print $shape->ddscat_parameter_data();
print Dump( $shape->parameters() );

print "Done.\n";
