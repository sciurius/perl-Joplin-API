#! perl

use strict;
use warnings;
use utf8;

package Joplin::Base;

use Carp;

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

sub _get_property {
    my ( $self, $name ) = splice( @_, 0, 2 );
    if ( @_ >= 1 ) {
	croak("Joplin: Property '$name' is read-only");
    }
    $self->{$name};
}

sub _set_get_property :lvalue {
    my ( $self, $name ) = splice( @_, 0, 2 );
    if ( @_ == 1 ) {
	$self->{$name} = $_[0];
    }
    $self->{$name};
}

sub _set_property_handlers {
    my ( $pkg, $rwprops, $roprops ) = @_;
    no strict 'refs';
    foreach ( @$rwprops ) {
	my $attr = $_;		# lexical for closure
	*{$pkg.'::'.$_} = sub :lvalue {
	    splice( @_, 1, 0, $attr );
	    goto &_set_get_property;
	};
    }
    foreach ( @$roprops ) {
	my $attr = $_;		# lexical for closure
	*{$pkg.'::'.$_} = sub {
	    splice( @_, 1, 0, $attr );
	    goto &_get_property;
	};
    }
    *{$pkg.'::'.'properties'} = sub {
	my ( $self, $what ) = @_;
	my @res;
	if ( !$what ) {
	    push( @res, @$roprops, @$rwprops );
	}
	elsif ( $what eq 'ro' ) {
	    push( @res, @$roprops );
	}
	elsif ( $what eq 'rw' ) {
	    push( @res, @$rwprops );
	}
	wantarray ? @res : \@res;
    };
}

sub iso8601date {
    my ( $self, $time ) = shift(@_)/1000 || time;
    my @tm = localtime($time);
    sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
             1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
}

1;
