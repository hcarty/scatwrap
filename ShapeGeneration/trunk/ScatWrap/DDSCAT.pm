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
use ScatWrap::Math;

use strict;
use warnings;

extends 'ScatWrap::Shape';

# Store the DDSCAT-ready vertices (1x1x1 grid, remove dup's).
has 'unique_dipoles' => ( isa => 'ArrayRef', is => 'rw' );
has 'surface_dipoles' => ( isa => 'ArrayRef', is => 'rw' );

has 'io' => (
    isa => 'ScatWrap::IO',
    is => 'ro',
    default => sub { ScatWrap::IO->new() }
);

has 'parameters' => ( isa => 'HashRef', is => 'rw' );
has 'results' => ( isa => 'HashRef', is => 'rw' );
has 'output_filenames' => (
    isa => 'HashRef',
    is => 'ro',
    default => {
        log => 'ddscat.log_*',
        mtable => 'mtable',
        qtable => 'qtable',
        qtable2 => 'qtable2',
        wsca => 'w*.sca',
        wavg => 'w*.avg',
    }
);

=head2 load_shape_from_file
Description:
This is extended slightly from the ScatWrap::Shape->load_shape_from_file
routine to automatically compute the unique dipoles within the entire shape.

It leaves the unique dipoles in a form usable by DDSCAT in the C<unique_dipoles>
attribute.

Arguments:
See ScatWrap::Shape->load_shape_from_file

Returns:
See ScatWrap::Shape->load_shape_from_file
=cut
after 'load_shape_from_file' => sub {
    my $self = shift;

    # Convert the dipole vertex coordinates to integer values.
    my %truncated_vertices;
    for my $object ( @.objects ) {
        for my $dipole ( @{ $object->{dipoles} } ) {
            # Generate a vertex key so that we don't duplicate points.
            my $vertex_key = join ' ', map { int $_ } @{ $dipole };
            $truncated_vertices{ $vertex_key } = 1;
        }
    }

    # XXX There's probably a better way to handle this, rather than joining and re-splitting...
    my @unique_vertices = map { [ split /\s+/ ] } keys %truncated_vertices;
    ./unique_dipoles( [ @unique_vertices ] );

    # Calculate and save the surface dipoles.
    my @indices = ScatWrap::Math::get_surface_dipoles( ./unique_dipoles() );
    print @indices . " of " . @unique_vertices . " are on the outside.\n";
    ./surface_dipoles( [ @.unique_dipoles[ @indices ] ] );
};

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

    # The data to return.
    my $shape_data;

    # A descriptive header.
    #XXX: This should be done as a heredoc probably, but this is easier (interpolation) for now.
    $shape_data =
        "Shape information for " . ./origin() . "\n"
        . scalar( @.unique_dipoles ) . " = Number of dipoles in the system\n"
        . "1 1 1 = x, y, z components of a1\n"
        . "1 1 1 = x, y, z components of a2\n"
        . "Dummy line due to prior non-cubic latice support in ddscat\n"
        . "Dipole xPos yPos zPos xComposition yComposition zComposition\n";

    # Now list out all of the vertices.
    my $vertex_number = 0;
    my $material = '1 1 1'; # XXX: Allow for anisotropic material??

    for my $dipole ( @.unique_dipoles ) {
        $shape_data .= ++$vertex_number . " $dipole $material\n";
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

=head2 to_file
Description:
Write the generated dipole information out to disk in a format usable by
ddscat.  This should generally be used for writing out a 'shape.dat' file and
a 'ddscat.par' file for use by ddscat.
WARNING: The given filenames will be overwritten if they already exist.

Arguments:
NOTE: If no values are provided, the subroutine will default to what ddscat
expects for input.
- parameter_filename - OPTIONAL, NAMED - Filename to save the parameter data to.
- shape_filename - OPTIONAL, NAMED - Filename to save the shape data to.

Returns:
None.
=cut
sub to_file ( $self, +$parameter_filename of Str, +$shape_filename of Str ) {

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

=head2 to_database
XXX: Terrible hack!
Description:

Arguments:

Returns:
=cut
sub to_database ( $self ) {

    # Keep track of the id value(s) as we move along so that db relational integrity is maintained.

    # First, save the input information.
    my $dda_shape_id = ./io->save(
        dda_shapes => {
            name => ./name(),
            description => ./description(),
            scalex => ./scale()->{x},
            scaley => ./scale()->{y},
            scalez => ./scale()->{z},
            origin => ./origin(),
            data => Dump(
                {
                    objects => ./objects(),
                    faces => ./faces(),
                    vertices => ./vertices(),
                }
            ),
        }
    );
    my $ddscat_shape_id = ./io->save(
        ddscat_shapes => {
            dda_shape_id => $dda_shape_id,
            data => ./ddscat_shape_data(),
        }
    );
    my $ddscat_parameter_id = ./io->save(
        ddscat_parameters => {
            ddscat_shape_id => $ddscat_shape_id,
            yaml => Dump( ./parameters() ),
            data => ./ddscat_parameter_data(),
        }
    );

    # Now, save the result(s) of the run.
    my $ddscat_run_id = ./io->save(
        ddscat_runs => {
            ddscat_parameter_id => $ddscat_parameter_id,
            description => "A run for me!",
        }
    );
    # Each of these items are saved separately, but they each have the same db structure.
    for my $data_type ( keys %{ ./results() } ) {
        for my $data ( @{ ./results()->{ $data_type } } ) {
            ./io->save(
                "ddscat_output_$data_type" => {
                    ddscat_run_id => $ddscat_run_id,
                    filename => $data->{name},
                    data => $data->{data},
                }
            );
        }
    }
}

=head2 run_ddscat
Description:
Run the actual ddscat executable, using the current object's data.
NOTE: TODO: XXX: ASSUMES THE ddscat EXECUTABLE IS IN A FIXED LOCATION...  THIS NEEDS TO BE CONFIGURABLE.

Arguments:
None.

Returns:
None.
=cut
sub run_ddscat ( $self ) {

    # Save the information out to a file which ddscat can use.
    ./to_file();

    # TODO: Allow for an arbitrarily positioned ddscat executable...  This just needs a general cleanup.

    # Go to where the ddscat magic will happen.
    # XXX: The 'use' is here because I don't want to keep this method around.
    use Cwd qw/chdir getcwd/;
    my $original_directory = getcwd();
    chdir 'ddscat'
        or die "Shit, yo: $!";
    my $ddscat_return_value = `bash ddscat.sh`;


    # TODO: DEBUGGING, don't really need this line??  Something /real/ should be done with this.
    warn "ddscat spat out: $ddscat_return_value"
        if $ddscat_return_value;

    my %ddscat_output_filenames;
    for my $key ( keys %{ ./output_filenames() } ) {
        $ddscat_output_filenames{ $key } = [ glob ./output_filenames()->{$key} ];
    }

    my %ddscat_output_data;
    for my $key (keys %ddscat_output_filenames) {
        for my $filename (@{ $ddscat_output_filenames{ $key } }) {
            # TODO: Handle this better - we should be able to continue somehow from here if the output can't be read.
            open my $INFILE, $filename
                or die "Unable to open DDSCAT output file $filename: $!";

            push @{ $ddscat_output_data{ $key } }, {
                name => $filename,
                data => join( "", <$INFILE> )
            };
        }
    }

    # Go back home.
    chdir $original_directory;

    # Save the results.
    ./results(\%ddscat_output_data);
}

1;
