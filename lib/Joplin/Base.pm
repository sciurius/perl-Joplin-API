#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Base;

sub api() :lvalue {
    $_[0]->{_api};
}

sub ping() {
    $_[0]->api->ping;
}

sub get_notes {
    my ( $self ) = @_;
    if ( $self->isa("Joplin::Folder") ) {
	$self->api->get_folder_notes;
    }
    else {
	...;
    }
}

sub _set_get_property :lvalue {
    my ( $self, $name ) = splice( @_, 0, 2 );
    if ( @_ == 1 ) {
	$self->{$name} = $_[0];
    }
    $self->{$name};
}

sub _set_property_handlers {
    my ( $pkg, $props ) = @_;
    no strict 'refs';
    foreach ( @$props ) {
	my $attr = $_;		# lexical for closure
	*{$pkg.'::'.$_} = sub :lvalue {
	    splice( @_, 1, 0, $attr );
	    goto &_set_get_property;
	};
    }
}

sub iso8601date {
    my ( $self, $time ) = shift(@_)/1000 || time;
    my @tm = localtime($time);
    sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
             1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
}

1;
