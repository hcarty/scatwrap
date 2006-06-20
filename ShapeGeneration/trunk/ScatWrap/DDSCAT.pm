package ScatWrap::DDSCAT;

=head1 ScatWrap::DDSCAT;
XXX: Write some docs!
=cut

use Moose;
use Perl6::Subs;
use Perl6::Attributes;

use ScatWrap::IO;

use strict;
use warnings;

extends 'ScatWrap::Shape';

has 'io' => (
    isa => 'ScatWrap::IO',
    is => 'ro',
    default => sub { ScatWrap::IO->new() }
);

=head2
Description:
Gives the shape information in a ddscat-usable format.

Arguments:
None.

Returns:
1. Text formatted for input to ddscat.
=cut
sub ddscat_data ( $self ) {

    # Convert the vertex coordinates to integer values.
    my %truncated_vertices;
    for my $object ( @.objects ) {
        for my $dipole ( @{ $object->{dipoles} } ) {
            # Generate a vertex key so that we don't duplicate points.
            my $vertex_key = join ' ', map { int $_ } @{ $dipole };
            $truncated_vertices{ $vertex_key } = 1;
        }
    }

    # The data to return.
    my $ddscat_data;

    # A descriptive header.
    #XXX: This should be done as a heredoc probably, but this is easier (interpolation) for now.
    $ddscat_data =
        "Shape information for " . ./origin() . "\n"
        . scalar( keys %truncated_vertices ) . " = Number of dipoles in the system\n"
        . "1 1 1 = x, y, z components of a1\n"
        . "1 1 1 = x, y, z components of a2\n"
        . "Dipole xPos yPos zPos xComposition yComposition zComposition\n";

    # Now list out all of the vertices.
    my $vertex_number = 0;
    my $material = '1 1 1'; # XXX: Allow for anisotropic material??

    for my $vertex_key ( keys %truncated_vertices ) {
        $ddscat_data .= ++$vertex_number . " $vertex_key $material\n";
    }

    return $ddscat_data;
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

    # Open the file for writing.  Overwrite if it already exists.
    open my $OUTFILE, ">$filename"
        or die "Unable to open $filename for writing: $!";

    print $OUTFILE ./ddscat_data();
}

1;
