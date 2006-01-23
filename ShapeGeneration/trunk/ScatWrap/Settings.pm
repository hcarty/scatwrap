package ScatWrap::Settings;

use Perl6::Attributes;
use Perl6::Subs;
use Spiffy -base;

use strict;
use warnings;

field 'filename' = 'scatwrap_settings.yaml';
field 'settings';

sub new ( $object_class, ?$filename of Str ) {

    my $self = bless( {}, $object_class );

    $.filename = $filename ? $filename : $.filename;
    $self->_load_settings();

    return $self;
}

sub _load_settings ( $self ) {

    # Open the file and load the settings from disk.
    open( YAMLIN, $.filename )
      or die "Can not open " . $.filename . ": $!";
    while ( <YAMLIN> ) { $yaml_text .= $_; }

    $.settings = Load($.filename);
}

1;
