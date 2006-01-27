package ScatWrap::Settings;

use Perl6::Attributes;
use Perl6::Subs;
use Spiffy -base;

use strict;
use warnings;

field 'filename' = 'settings.yaml';
field 'etc';
field 'db';

sub new ( $object_class, ?$filename of Str ) {

    my $self = bless( {}, $object_class );

    ./filename( $filename ? $filename : ./filename() );
    $self->_load_settings();
    return $self;
}

sub _load_settings ( $self ) {

    my $yaml_text;
    # Open the file and load the settings from disk.
    open( my $YAMLIN, ./filename() )
      or die "Can not open " . ./filename() . ": $!";
    while ( <$YAMLIN> ) { $yaml_text .= $_; }
    close($YAMLIN);

    my ($db, $etc) = Load($yaml_text);
    ./db($db);
    ./etc($etc);
}

1;
