package ScatWrap::Shape;

use Data::Dumper;
use Perl6::Attributes;
use Perl6::Subs;
use Spiffy -base;

use ScatWrap::Math;

# Write good/clean code, and turn on warnings.
use strict;
use warnings;

# Declare some subroutines.
use subs qw( new            _load_shape     add_object
             add_vertex     add_face        print_shape );

#----
# Class fields/attributes.
#----
field 'name';
field 'input_file';
field 'scale' => { x => 1, y => 1, z => 1 };
field 'objects' => [];
field 'faces' => [];
field 'vertices' => [];

####
#
# Description:
# Class constructor.
#
# Arguments: (all named)
# input_file => Name of the input file to load and process. (OPTIONAL)
# scale      => hashref of { x => $x_scale, y => $y_scale, z => $z_scale }
#               Determines how much to scale the input_file data by. (OPTIONAL)
# 
# Note:
# If either input_file or scale are used as arguments, then they must both be used.
# If neither of these arguments are provided, then the item must be built by hand.
#
# Returns:
# An object of ScatWrap::Shape
# 
####
sub new ( $object_class, +$input_file of Str, +$scale of Hash, +$manual of Str ) {

    my $self = bless( {}, $object_class );
    unless ( $manual ) {
        # We need an input file and scaling values if the body isn't going to
        # be built manually.
        if ( $input_file ) { $.input_file = $input_file }
        else { die 'Must set "input_file" value' }
        if ( $scale->{x} and $scale->{y} and $scale->{z} ) { $.scale = $scale }
        else { die 'Must set x, y, z keys for "scale" value' }

        # Load the given file, unless the 'manual' flag is set, in which case it's
        # up to the user/caller to provide and build the appropriate data.
        $self->_load_shape();
    }

    return $self;
}

####
#
# Description:
# Read the shape input file in Wavefront (.obj, as exported from Wings3D)
# format from disk.
#
# Arguments:
# 1. Filename to load the shape information from.
#
# Returns:
# dies on error.  Use eval for error checking.
#
# TODO: Add (better) error checking to the file reading routines.  This
#       is/will be handled by eval + die.
# TODO: Change this function so that it is a 'generic' shape loading
#       function, which calls the appropriate function based on the given
#       file's extension.
# TODO: Allow the user to pass in a blob of text containing the shape
#       information, to make web life easier.
#
####
sub _load_shape ( $self ) {

    open( my $SHAPEFILE, $.input_file )
      || die "Problem with input file '$.input_file': $!";

    # Hold on to the name of the current object.
    my $this_object_name = '';

    # Read in the file line by line.
    while ( my $line = <$SHAPEFILE> ) {
        # Skip the line if it isn't a vertex, face, or new object.
        next if ( $line !~ /^[vfo] /i );

        # Break the line into parts.
        my ( $type, @parts ) = split( ' ', $line );

        if    ( lc( $type ) eq 'o' ) {
            # Only add an object if there is something to add.
            ./add_object($this_object_name) if $this_object_name;
            # Save the object's name
            $this_object_name = $parts[0];
        }
        elsif ( lc( $type ) eq 'v' ) { ./add_vertex(@parts)     }
        elsif ( lc( $type ) eq 'f' ) { ./add_face(\@parts)      }
    }

    # Add the last object in the file.
    ./add_object($this_object_name);

    # We're done with the file, close it up.
    close($SHAPEFILE);
}

sub add_vertex ( $self, $vx of Num, $vy of Num, $vz of Num ) {

    # Scale the vertices and push them on to the end of the list.
    push( @.vertices, [
                        $vx * $.scale{x},
                        $vy * $.scale{y},
                        $vz * $.scale{z}
                      ] );
}

sub add_face ( $self, $parts of Array ) {

    # Face information comes in vertex sets.
    # We only care about the first 3.

    # A regexp to clean up the data -> Go from 1//1 to 1.  (See an .obj file).
    # Also adjust the number to be Perl-array-offset friendly.
    my @indices = map { $_ =~ s|^(\d+)//\d+|$1|; $_ -= 1; } @$parts;
    # Collect the vertex information for this face.
    my @vertices = ( $.vertices[ $indices[0] ],
                     $.vertices[ $indices[1] ],
                     $.vertices[ $indices[2] ] );

    push( @.faces, {
                        vertices => [ @vertices ],
                        plane    => [ ScatWrap::Math::create_plane(@vertices) ],
                        normal   => [ ScatWrap::Math::plane_normal(@vertices) ]
                   } );
}

sub add_object ( $self, $object_name of Str ) {

    # Save it, and generate the dipoles while we're at it.
    # XXX: This is fixed at a 1x1x1 resolution for now, because that's what ddscat wants.
    #      It can be changed in the future if needed, but should probably stay this way for now.
    push( @.objects, {
                        name    => $object_name,
                        faces   => [ @.faces ],
                        dipoles => [ ScatWrap::Math::create_dipoles( [ @.faces ], { x => 1, y => 1, z => 1 } ) ]
                     } );
    # Clear out @faces.
    splice( @.faces, 0 );
}

# Print the shape out on the screen.
sub print_shape ( $self ) {

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;

    print "\nObjects: \n";
    foreach (@.objects) {
        print Dumper($_) . "\n";
    }

    print "\nFaces: \n";
    foreach (@.faces) {
        print Dumper($_) . "\n";
    }

    print "\nVertices: \n";
    foreach (@.vertices) {
        print Dumper($_) . "\n";
    }
}

####
#
# Description:
# Write the generated dipole information out to disk in a format usable by
# ddscat.  This should generally be used for writing out a 'shape.dat' file
# for use by ddscat.
# WARNING: The given filename will be overwritten if it already exists.
#
# Arguments:
# 1. Filename to save the data to.
#
# Returns:
# dies on failure.  Use eval for error checking.
#
# TODO: Convert this to use Template::Toolkit or something similar.
#
####
sub save_dda_data ( $self, $filename of Str ) {

    # Convert the vertex coordinates to integer values.
    my %truncated_vertices;
    foreach my $object ( @.objects ) {
        foreach my $dipole ( @{ $object->{dipoles} } ) {
            # Generate a vertex key so that we don't duplicate points.
            my $vertex_key = join( ' ', map { int($_) } @{ $dipole } );
            $truncated_vertices{ "$vertex_key" } = 1;
        }
    }

    # Open the file for writing.  Overwrite if it already exists.
    open( OUTFILE, ">$filename" )
      || die "Unable to open $filename for writing: $!";

    # Print out a descriptive header.
    print OUTFILE "Shape information for " . $.input_file . "\n";
    print OUTFILE scalar( keys(%truncated_vertices) ) . " = Number of dipoles in the system\n";
    print OUTFILE "1 1 1 = x, y, z components of a1\n";
    print OUTFILE "1 1 1 = x, y, z components of a2\n";
    print OUTFILE "Dipole xPos yPos zPos xComposition yComposition zComposition\n";

    # Now list out all of the vertices.
    my $vertex_number = 0;
    my $material = '1 1 1'; # XXX: Allow for anisotropic material??

    foreach my $vertex_key ( keys(%truncated_vertices) ) {
        print OUTFILE ++$vertex_number . " $vertex_key $material\n";
    }

    # We're finished.  Close the file.
    close(OUTFILE);
}

1;
