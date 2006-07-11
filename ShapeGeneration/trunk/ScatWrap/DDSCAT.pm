package ScatWrap::DDSCAT;

=head1 ScatWrap::DDSCAT;
XXX: Write some docs!
=cut

use Moose;
use Template;
use YAML;
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

has 'parameters' => ( isa => 'HashRef', is => 'rw' );

=head2 ddscat_shape_data
Description:
Gives the shape information in a ddscat-usable format.

Arguments:
None.

Returns:
1. Text formatted for input to ddscat (though it should probably be written to a file first).

#TODO: Change this function to use Template::Toolkit or some other templating package.
=cut
sub ddscat_shape_data ( $self ) {

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
    my $shape_data;

    # A descriptive header.
    #XXX: This should be done as a heredoc probably, but this is easier (interpolation) for now.
    $shape_data =
        "Shape information for " . ./origin() . "\n"
        . scalar( keys %truncated_vertices ) . " = Number of dipoles in the system\n"
        . "1 1 1 = x, y, z components of a1\n"
        . "1 1 1 = x, y, z components of a2\n"
        . "Dummy line due to prior non-cubic latice support in ddscat\n"
        . "Dipole xPos yPos zPos xComposition yComposition zComposition\n";

    # Now list out all of the vertices.
    my $vertex_number = 0;
    my $material = '1 1 1'; # XXX: Allow for anisotropic material??

    for my $vertex_key ( keys %truncated_vertices ) {
        $shape_data .= ++$vertex_number . " $vertex_key $material\n";
    }

    #TODO: Convert this to use Template::Toolkit or something similar.
    return $shape_data;
}

=head2 ddscat_parameter_data
Description:
Gives the ddscat parameter information in a ddscat-usable format.

Arguments:
None.

Returns:
1. Text formatted for input to ddscat (though it should probably be written to a file first).
=cut
sub ddscat_parameter_data ( $self ) {

    my $template = Template->new();
    my $output = '';
    $template->process( 'ddscat.par.tt2', ./parameters(), \$output )
        or die "Template processing error: " . $template->error();
    return $output;
}

=head2 save_dda_data
Description:
Write the generated dipole information out to disk in a format usable by
ddscat.  This should generally be used for writing out a 'shape.dat' file and
a 'ddscat.par' file for use by ddscat.
WARNING: The given filenames will be overwritten if they already exist.

Arguments:
- parameter_filename - OPTIONAL, NAMED - Filename to save the parameter data to.
- shape_filename - OPTIONAL, NAMED - Filename to save the shape data to.

Returns:
None.
=cut
sub save_dda_data ( $self, +$parameter_filename of Str, +$shape_filename of Str ) {

    # If no filename was given, use a default name.
    $parameter_filename = $parameter_filename
                          ? $parameter_filename
                          : 'ddscat.par';
    $shape_filename = $shape_filename
                      ? $shape_filename
                      : 'shape.dat';
    # Open the file(s) for writing.  Overwrite if it already exists.
    open my $PARAMFILE, ">$parameter_filename"
        or die "Unable to open $parameter_filename for writing: $!";
    open my $SHAPEFILE, ">$shape_filename"
        or die "Unable to open $shape_filename for writing: $!";

    print $SHAPEFILE ./ddscat_shape_data();
    print $PARAMFILE ./ddscat_parameter_data();
}

=head2 save_to_database
XXX: Terrible hack!
Description:

Arguments:

Returns:
=cut
sub save_to_database ( $self ) {

    ./io->save(
        'ddscat_shapes',
        {
            dda_shape_id => ./origin(),
            data => ./ddscat_shape_data(),
        }
    );
    ./io->save(
        'ddscat_parameters',
        {
            ddscat_shape_id => ./origin(),
            yaml => Dump( ./parameters() ),
            data => ./ddscat_parameter_data(),
        }
    );
}

=head2 TRASH IT ALL
Description:

Arguments:

Returns:
=cut
sub set_default_parameters ( $self ) {

    ./parameters(
        {
            torque => 'NOTORQ',
            solution_method => 'PBCGST',
            fft_method => 'GPFAFT',
            dispersion_relation => 'LATTDR',
            binary_dump => 'NOTBIN',
            netcdf => 'NOTCDF',
            shape => {
                type => 'FRMFIL',
                parameters => [ qw/32 24 16/ ],
            },
            dielectric => {
                num => 1,
                type => 'H2OICE',
                filenames => [ ],
            },
            init => 0,
            error_tolerance => 1.00e-5,
            eta => 0.5,
            wavelengths => {
                first => 6.283185,
                last => 6.283185,
                num => 1,
                choice => 'INV',
            },
            radii => {
                first => 2,
                last => 2,
                num => 1,
                choice => 'LIN',
            },
            polarization => {
                x => '0,0',
                y => '1.,0.',
                z => '0.,0.',
                orthogonal => 2,
            },
            write_sca => 1,
            beta => {
                min => 0,
                max => 0,
                num => 1,
            },
            theta => {
                min => 0,
                max => 90,
                num => 3,
            },
            phi => {
                min => 0,
                max => 0,
                num => 1,
            },
            iwav => 0,
            irad => 0,
            iori => 0,
            s => {
                num => 6,
                elements => [ qw/ 11 12 21 22 31 41 / ],
            },
            scattering_planes => [
                {
                    phi => 0,
                    theta => {
                        min => 0,
                        max => 180,
                        delta => 10,
                    },
                },
                {
                    phi => 90,
                    theta => {
                        min => 0,
                        max => 180,
                        delta => 10,
                    },
                },
            ],
        }
    );
}

1;
