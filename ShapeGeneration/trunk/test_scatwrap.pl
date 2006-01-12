#!/usr/bin/perl

use Perl6::Subs;
use ScatWrap::Shape;
use YAML;

use strict;
use warnings;

# Handle command line arguments.
my $input_file = $ARGV[0] ? $ARGV[0] : 'HexagonalRosette.obj';
my $scale = { x => ( $ARGV[1] ? $ARGV[1] : 1 ),
              y => ( $ARGV[2] ? $ARGV[2] : 1 ),
              z => ( $ARGV[3] ? $ARGV[3] : 1 ) };

my $shape = ScatWrap::Shape->new( input_file => $input_file,
                                  scale      => $scale );

$shape->save_dda_data('test.dat');

print "Done.\n";

open( YAMLFILE, ">test.yaml" )
  || die "OH NO!  NO YAML! : $!";
print YAMLFILE Dump($shape);
close( YAMLFILE );
