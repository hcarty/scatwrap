package ScatWrap::Math;

=head1 ScatWrap::Math
=cut
=head1 TODO
# TODO Change all block comments to use POD instead.
=cut

use List::Util;
use Math::Trig;
use PDL;

use strict;
use warnings;

use constant PI => 4 * atan2(1,1);

=head1 DIPOLE CREATION ROUTINES
=head2 create_plane
Description:
Takes 3 points and comes up with the equation for the plane which contains
those points.

Arguments:
1-3. Array-refs holding the points - ie. $p1->[0] = x-val, $p1->[1] = y-val, etc.

Returns:
The A,B,C,D coefficients for the generated plane.
=cut
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

=head2 plane_normal
Description:
Find the normal to a face/plane given 3 points.
NOTE - I<THE ORDER OF THE POINTS IS IMPORTANT.>  If you want consistent normals
you I<MUST> use consistent windings.

Arguments:
1-3. Array-refs holding the points.  See C<create_plane> above.

Returns:
A normalized vector which is normal to the given plane.
=cut
sub plane_normal {

    my ( $p1, $p2, $p3 ) = @_;

    my $point1  = pdl( $p1 );
    my $point2  = pdl( $p2 );
    my $point3  = pdl( $p3 );
    my $vector1 = $point1 - $point2;
    my $vector2 = $point3 - $point2;

    return list( norm( crossp( $vector2, $vector1 ) ) );
}

=head2 point_inside
Description:
Check a point to see if it is inside the given faces.

Arguments:
1. The point we are checking (arrayref -- [x, y, z]).
2. A set of faces which define the object bounds.  The checked object must be
closed and convex - this routine only works for a single, closed, convex
object.

Returns:
true if the point is inside the faces
else
undef if the point is outside
=cut
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

=head2 _dot_product
Description:
Calculate the dot product of two 3-element pdls.

Arguments:
1-2. Two 3 element pdls

Returns:
A scalar value (the dot product of the given pdls).
=cut
sub _dot_product {

    return sum( $_[0] * $_[1] );
}

=head2 create_dipoles
Description:
Create a set of dipoles based on a given set of faces.

Arguments:
1. Array of faces.
2. Resolution for dipole creation.

Returns:
An array of [x, y, z] dipole coordinates.
=cut
sub create_dipoles {

    my ( $faces, $resolution ) = @_;

    # The max and min values for each axis.
    my ( $x_max, $x_min, $y_max, $y_min, $z_max, $z_min ) = ( 0, 0, 0, 0, 0, 0 );

    # Find the spatial extent of the object.
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

=head1 UNSORTED ROUTINES
=head2 get_surface_dipoles
Description:
Given a list of dipoles, tell which ones are on the surface of the given set.

Arguments:
1. ArrayRef of [x,y,z] dipole coordinate triplets.
B<NOTE:> The coordinates must be on a unit (1x1x1) grid for this to provide
accurate results.

Returns:
XXX A list of the indices of the given dipoles which sit on the surface.

TODO Make sure points which have open space around them are really on the
outside and not just inside of, say, a hollow sphere.
TODO Determine exactly how much a given dipole should contribute to the surface
area of a shape.
TODO Decide if a "surface area point" should be able to be counted twice... ie
if (0, 0, 0) is a "surface" point for dipole A, should it also be able to be
counted as a "surface" point for dipole B?  It would lower the surface area
calculations on a very rough item, effectively smoothing it out somewhat, but the
results would probably be more accurate for a smooth object.
=cut
sub get_surface_dipoles {

    my $dipoles = shift;

    # A convenience function to set a key based on a x,y,z coordinate.
    my $point_key = sub { "$_[0] $_[1] $_[2]" };

    # Make a hash of the vertices -> indices.
    my %filled_points;
    for my $index (0 .. scalar(@$dipoles) - 1) {
        my $key = $point_key->( @{ $dipoles->[ $index ] } );
        $filled_points{ $key } = $index;
    }

    my %surface_indices;
    for my $dipole (@$dipoles) {
        my ($x, $y, $z) = @$dipole;

        # A convenience function to set which points to check.
        my $range = sub { ($_[0] - 1 .. $_[0] + 1) };

        my $dipole_key = $point_key->( $x, $y, $z );
        for my $i ( $range->($x) ) {
            for my $j ( $range->($y) ) {
                for my $k ( $range->($z) ) {
                    my $check_key = $point_key->( $i, $j, $k );
                    unless ( defined $filled_points{ $check_key } ) {
                        $surface_indices{ $filled_points{ $dipole_key } } += 1;
                    }
                }
            }
        }
    }

    return %surface_indices;
}

=head2 _distance_between_points
Description:
Find the distance between the two given [x,y,z] points.

Arguments:
1. Point 1 (ArrayRef of [x,y,z])
2. Point 2 (same as Point 1)

Returns:
A scalar value (the linear distance between the two points).
=cut
sub _distance_between_points {

    my $p1 = shift;
    my $p2 = shift;

    return sqrt(
          ($p1->[0] - $p2->[0])**2
        + ($p1->[1] - $p2->[1])**2
        + ($p1->[2] - $p2->[2])**2
    );
}

=head2 get_projected_cross_section
Description:
Calculate the projected cross section of the given set of dipoles.

Arguments:
1. ArrayRef of [x,y,z] dipole coordinate triplets.
2. Assumed radius of the dipoles.

Returns:
Orthogonally projected cross section of the given dipole figure, averaged over
several angles/orientations.

TODO Allow the user to give either a set of angles to use, or a number of
angles to iterate over when calculating the cross section.

B<NOTE:> The assumed radius tells the spatial extent of each dipole for
calculating collision detections.
=cut
sub get_projected_cross_section {

    my $dipoles = shift;
    my $dipole_radius = shift;

    # The max and min values for each axis.
    my ( $x_max, $x_min, $y_max, $y_min, $z_max, $z_min ) = ( 0, 0, 0, 0, 0, 0 );

    # Find the spatial extent of the object.
    for my $vertex ( @$dipoles ) {
        if    ( $vertex->[0] < $x_min ) { $x_min = int( $vertex->[0] ) - 1 }
        elsif ( $vertex->[0] > $x_max ) { $x_max = int( $vertex->[0] ) + 1 }
        if    ( $vertex->[1] < $y_min ) { $y_min = int( $vertex->[1] ) - 1 }
        elsif ( $vertex->[1] > $y_max ) { $y_max = int( $vertex->[1] ) + 1 }
        if    ( $vertex->[2] < $z_min ) { $z_min = int( $vertex->[2] ) - 1 }
        elsif ( $vertex->[2] > $z_max ) { $z_max = int( $vertex->[2] ) + 1 }
    }

    # Find a center point for the dipole collection.
    my $center = [
        ( $x_max + $x_min ) / 2,
        ( $y_max + $y_min ) / 2,
        ( $z_max + $z_min ) / 2
    ];

    # Find a reasonably distant point from the center...
    # TODO FIXME XXX Adjust the ( $dipole_radius * foo ) term to something better?
    my $radius = List::Util::max(
            _distance_between_points( $center, [ $x_min, $y_min, $z_min ] ),
            _distance_between_points( $center, [ $x_max, $y_max, $z_max ] )
    ) + ( $dipole_radius * 2 );
    # Now $center and $radius give us a sphere which completely encompasses the crystal.

    # TODO FIXME XXX Set these values to something that scales reasonably with the size of the crystal.
    my $Z_STEP = $radius / 20;
    my $PHI_STEP = PI / 20;

    # Move over the sphere to get a relatively even coverage of the crystal.
    for ( my $z = -($radius); $z <= $radius; $z += $Z_STEP ) {
        for ( my $phi = 0; $phi < PI; $phi += $PHI_STEP ) {
            my $theta = asin( $z / $radius );
            my $x = $radius * cos( $theta ) * cos( $phi );
            my $y = $radius * cos( $theta ) * sin( $phi );

            print _calculate_projected_cross_section( $dipoles, $dipole_radius, [ $x, $y, $z ], $center ) . "\n";
        }
    }
}

=head2 _calculate_projected_cross_section
Description:
Calculates the orthogonally projected cross section of the given dipole cloud
from/on the given plane.

Arguments:
1. ArrayRef of dipoles.
2. Radius of each dipole.
3. ArrayRef of a point ( [x,y,z] ) on the projection plane.
4. ArrayRef of the center-point in the crystal ( [x,y,z] ).

Returns:
A scalar value of the cross sectional area for the crystal on the given plane.
=cut
sub _calculate_projected_cross_section {

    my $dipole = shift;
    my $dipole_radius = shift;
    my $p1 = shift;
    my $center = shift;

    # Get a vector normal to the plane, facing the crystal.
    my $normal = [
        $center->[0] - $p1->[0],
        $center->[1] - $p1->[1],
        $center->[2] - $p1->[2]
    ];
}

1;
