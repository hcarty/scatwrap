package ScatWrap::Math;

use PDL;

use strict;
use warnings;

####
#
# Description:
# Take 3 points, [ $p1 $p2 $p3 ], and come up with the equation for the plane
# which contains those points.
#
####
sub create_plane {

    my ( $p1, $p2, $p3 ) = @_;

    my $D = determinant( pdl( [ [ $p1->[0], $p2->[0], $p3->[0] ],
                                [ $p1->[1], $p2->[1], $p3->[1] ],
                                [ $p1->[2], $p2->[2], $p3->[2] ] ] ) );
    my $A = determinant( pdl( [ [ 1,        $p2->[0], $p3->[0] ],
                                [ 1,        $p2->[1], $p3->[1] ],
                                [ 1,        $p2->[2], $p3->[2] ] ] ) );
    my $B = determinant( pdl( [ [ $p1->[0], 1,        $p3->[0] ],
                                [ $p1->[1], 1,        $p3->[1] ],
                                [ $p1->[2], 1,        $p3->[2] ] ] ) );
    my $C = determinant( pdl( [ [ $p1->[0], $p2->[0], 1        ],
                                [ $p1->[1], $p2->[1], 1        ],
                                [ $p1->[2], $p2->[2], 1        ] ] ) );

    return $A->at(0), $B->at(0), $C->at(0), $D->at(0);
}

####
#
# Description:
# Find the normal to a face/plane defined by 3 points.
# THE ORDER OF THE POINTS IS IMPORTANT.  If you want considtent normals, you
# MUST use consistent windings.
#
####
sub plane_normal {

    my ( $p1, $p2, $p3 ) = @_;

    my $point1  = pdl( $p1 );
    my $point2  = pdl( $p2 );
    my $point3  = pdl( $p3 );
    my $vector1 = $point1 - $point2;
    my $vector2 = $point3 - $point2;

    return list( norm( crossp( $vector2, $vector1 ) ) );
}

####
#
# Description:
# Check a point to see if it is inside the given faces.
#
# Arguments:
# 1. The point we are checking, in the format: [ x, y, z ].
# 2. A set of faces which set the object bounds.  Must be closed!
#    It only works on a SINGLE closed, convex set of faces.
#
# Returns:
# true if the point is inside the faces
# else
# undef if the point is outside
#
####
sub point_inside {

    my ( $point, $faces ) = @_;

    $point = pdl($point);

    foreach my $face ( @{ $faces } ) {
        my $plane_point = pdl( $face->{vertices}->[0] );
        my $plane_normal = pdl( $face->{normal} );
        my $distance = _dot_product( ( $point - $plane_point ),
                                     $plane_normal );

        # If $distance > 0, then the point is on the outside of this shape.
        return undef if $distance > 0;
    }

    # The point is inside if we make it here.
    return 1;
}

####
#
# Description:
# Calculate the dot product of two 3-element pdls.
#
# Arguments:
# 1-2. Two 3 element pdls
#
# Returns:
# A scalar value (the dot product)
#
####
sub _dot_product {

    return sum( $_[0] * $_[1] );
}

####
#
# Description:
# Create a set of dipoles based on a given set of faces.
#
# Arguments:
# 1. Array of faces.
# 2. Resolution for dipole creation.
#
# Returns:
# An array of [x y z] dipole coordinates.
#
####
sub create_dipoles {

    my ( $faces, $resolution ) = @_;

    # The max and min values for each axis.
    my ( $x_max, $x_min, $y_max, $y_min, $z_max, $z_min ) = ( 0, 0, 0, 0, 0, 0 );

    # Find the spatial exten of the object.
    foreach my $face ( @$faces ) {
        foreach my $vertex ( @{ $face->{vertices} } ) {
            if    ( $vertex->[0] < $x_min ) { $x_min = int( $vertex->[0] ) - 1 }
            elsif ( $vertex->[0] > $x_max ) { $x_max = int( $vertex->[0] ) + 1 }
            if    ( $vertex->[1] < $y_min ) { $y_min = int( $vertex->[1] ) - 1 }
            elsif ( $vertex->[1] > $y_max ) { $y_max = int( $vertex->[1] ) + 1 }
            if    ( $vertex->[2] < $z_min ) { $z_min = int( $vertex->[2] ) - 1 }
            elsif ( $vertex->[2] > $z_max ) { $z_max = int( $vertex->[2] ) + 1 }
        }
    }

    # Generate the contained dipoles.
    my @dipoles;
    for ( my $x = $x_min ; $x <= $x_max ; $x += $resolution->{x} ) {
        for ( my $y = $y_min ; $y <= $y_max ; $y += $resolution->{y} ) {
            for ( my $z = $z_min ; $z <= $z_max ; $z += $resolution->{z} ) {
                push( @dipoles, [ $x, $y, $z ] ) if point_inside( [ $x, $y, $z ], $faces );
            }
        }
    }

    return @dipoles;
}

1;
