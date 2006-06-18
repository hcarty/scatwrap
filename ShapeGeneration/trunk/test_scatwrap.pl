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
            "scale-z=i" => \$scale{z}
);


# Create the shape object and load the information from disk.
my $shape = ScatWrap::Shape->new( scale      => \%scale );
$shape->load_shape_from_file( $input_file );

# Save the generated dipoles in a DDA-friendly format.
$shape->save_dda_data('test.dat');

print "Done.\n";

# Spit the data out to YAML land too, just for fun...
open my $YAMLFILE, ">test.yaml"
    or die "OH NO!  NO YAML! : $!";
print $YAMLFILE Dump($shape);
close $YAMLFILE;
