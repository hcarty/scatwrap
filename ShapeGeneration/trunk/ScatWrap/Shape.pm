package ScatWrap::Shape;

use Data::Dumper;
use Perl6::Attributes;
use Perl6::Subs;
use Moose;

use ScatWrap::Math;

use strict;
use warnings;

#----
# Class fields/attributes.
#----
has 'name' => ( isa => 'Str', is => 'rw' );
has 'origin' => ( isa => 'Str', is => 'rw' );
has 'scale' => (
    isa => 'HashRef',
    is => 'rw',
    default => { x => 1, y => 1, z => 1 }
);
has 'objects' => ( isa => 'ArrayRef', is => 'rw' );
has 'faces' => ( isa => 'ArrayRef', is => 'rw' );
has 'vertices' => ( isa => 'ArrayRef', is => 'rw' );

=head2 load_shape_from_file
Description:
Read the shape input file in Wavefront (.obj, as exported from Wings3D)
format from disk.

Arguments:
1. Filename to load the shape information from.

Returns:
dies on error.  Use eval for error checking.

#TODO: Add (better) error checking to the file reading routines.  This
#      is/will be handled by eval + die.
#TODO: Change this function so that it is a 'generic' shape loading
#      function, which calls the appropriate function based on the given
#      file's extension.
#TODO: Allow the user to pass in a blob of text containing the shape
#      information, to make web life easier.
=cut
sub load_shape_from_file ( $self, $input_file ) {

    open my $SHAPEFILE, $input_file
        or die "Problem with input file '$input_file': $!";

    # Hold on to the name of the current object.
    my $this_object_name = '';

    # Read in the file line by line.
    while ( my $line = <$SHAPEFILE> ) {
        # Skip the line if it isn't a vertex, face, or new object.
        next if ( $line !~ /^[vfo] /i );

        # Break the line into parts.
        my ( $type, @parts ) = split ' ', $line;

        if ( lc $type eq 'o' ) {
            # Only add an object if there is something to add.
            ./add_object($this_object_name) if $this_object_name;
            # Save the object's name
            $this_object_name = $parts[0];
        }
        elsif ( lc $type eq 'v' ) { ./add_vertex(@parts)     }
        elsif ( lc $type eq 'f' ) { ./add_face(\@parts)      }
    }

    # Add the last object in the file.
    ./add_object($this_object_name);

    # We're done with the file, close it up.
    #XXX: Get rid of this... we don't really need to close the filehandle scalar.
    close $SHAPEFILE;

    # Save where the data came from.
    #XXX: THIS SHOULD BE HANDLED BETTER...
    ./origin( $input_file );
}

=head2 add_vertex
Description:
Add a vertex to the list.

Arguments:
1-3. x, y, z

Returns:
None.
=cut
sub add_vertex ( $self, $vx of Num, $vy of Num, $vz of Num ) {

    # Scale the vertices and push them on to the end of the list.
    push @.vertices, [
                        $vx * $.scale{x},
                        $vy * $.scale{y},
                        $vz * $.scale{z}
    ];
}

=head2 add_face
Description:
Add a face to the shape.

Arguments:
1. An array of parts!

Returns:
None.
=cut
sub add_face ( $self, $parts of Array ) {

    # Face information comes in vertex sets.
    # We only care about the first 3.

    # A regexp to clean up the data -> Go from 1//1 to 1.  (See an .obj file).
    # Also adjust the number to be Perl-array-offset friendly.
    my @indices = map { $_ =~ s|^(\d+)//\d+|$1|; $_ -= 1; } @$parts;
    # Collect the vertex information for this face.
    my @vertices = ( $.vertices[ $indices[0] ],
                     $.vertices[ $indices[1] ],
                     $.vertices[ $indices[2] ]
    );

    push @.faces, {
                    vertices => [ @vertices ],
                    plane    => [ ScatWrap::Math::create_plane(@vertices) ],
                    normal   => [ ScatWrap::Math::plane_normal(@vertices) ]
    };
}

=head2 add_object
Description:
Add an object to the shape.

Arguments:
1. A name for the object being added.

Returns:
None.
=cut
#XXX: This should probably be made in to a purely internal function?  Or not??
sub add_object ( $self, $object_name of Str ) {

    # Save it, and generate the dipoles while we're at it.
    # XXX: This is fixed at a 1x1x1 resolution for now, because that's what ddscat wants.
    #      It can be changed in the future if needed, but should probably stay this way for now.
    push @.objects, {
                        name    => $object_name,
                        faces   => [ @.faces ],
                        dipoles => [ ScatWrap::Math::create_dipoles( [ @.faces ], { x => 1, y => 1, z => 1 } ) ]
    };
    # Clear out @faces.
    splice @.faces, 0;
}

# Print the shape out on the screen.
sub print_shape ( $self ) {

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Terse = 1;

    print "\nObjects: \n";
    for (@.objects) {
        print Dumper($_) . "\n";
    }

    print "\nFaces: \n";
    for (@.faces) {
        print Dumper($_) . "\n";
    }

    print "\nVertices: \n";
    for (@.vertices) {
        print Dumper($_) . "\n";
    }
}

=head2 save_dda_data
Description:
Write the generated dipole information out to disk in a format usable by
ddscat.  This should generally be used for writing out a 'shape.dat' file
for use by ddscat.
WARNING: The given filename will be overwritten if it already exists.

Arguments:
1. Filename to save the data to.

Returns:
None.
dies on failure.  Use eval for error checking.

TODO: Convert this to use Template::Toolkit or something similar.
=cut
sub save_dda_data ( $self, $filename of Str ) {

    # Convert the vertex coordinates to integer values.
    my %truncated_vertices;
    for my $object ( @.objects ) {
        for my $dipole ( @{ $object->{dipoles} } ) {
            # Generate a vertex key so that we don't duplicate points.
            my $vertex_key = join( ' ', map { int($_) } @{ $dipole } );
            $truncated_vertices{ "$vertex_key" } = 1;
        }
    }

    # Open the file for writing.  Overwrite if it already exists.
    open my $OUTFILE, ">$filename"
        or die "Unable to open $filename for writing: $!";

    # Print out a descriptive header.
    print $OUTFILE "Shape information for " . ./origin() . "\n";
    print $OUTFILE scalar( keys(%truncated_vertices) ) . " = Number of dipoles in the system\n";
    print $OUTFILE "1 1 1 = x, y, z components of a1\n";
    print $OUTFILE "1 1 1 = x, y, z components of a2\n";
    print $OUTFILE "Dipole xPos yPos zPos xComposition yComposition zComposition\n";

    # Now list out all of the vertices.
    my $vertex_number = 0;
    my $material = '1 1 1'; # XXX: Allow for anisotropic material??

    for my $vertex_key ( keys(%truncated_vertices) ) {
        print $OUTFILE ++$vertex_number . " $vertex_key $material\n";
    }

    # We're finished.  Close the file.
    #XXX: Get rid of this ... we don't need to close the filehandle scalar manually.
    close($OUTFILE);
}

1;
