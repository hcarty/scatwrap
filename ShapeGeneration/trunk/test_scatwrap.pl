#!/usr/bin/perl

use Getopt::Long;
use ScatWrap::DDSCAT;
use YAML;
use Data::Dumper;

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
$shape->set_default_parameters();
$shape->save_dda_data( shape_filename => 'test.dat', parameter_filename => 'test.par' );
$shape->save_to_database();

print "Done.\n";
