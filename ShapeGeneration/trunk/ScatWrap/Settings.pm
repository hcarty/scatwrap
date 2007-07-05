package ScatWrap::Settings;

use Moose;

use strict;
use warnings;

has 'filename' => (
    isa => 'Str',
    is => 'rw',
    default => 'settings.yaml'
);
has 'etc';
has 'db';

sub new {

    my ( $object_class, $filename ) = @_;

    my $self = bless {}, $object_class;

    $self->filename( $filename ? $filename : $self->filename() );
    $self->_load_settings();
    return $self;
}

sub _load_settings {

    my $self = shift;

    my $yaml_text;
    # Open the file and load the settings from disk.
    open( my $YAMLIN, $self->filename() )
      or die "Can not open " . $self->filename() . ": $!";
    while ( <$YAMLIN> ) { $yaml_text .= $_; }
    close($YAMLIN);

    my ($db, $etc) = Load($yaml_text);
    $self->db($db);
    $self->etc($etc);
}

1;
