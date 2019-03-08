#! perl

use strict;
use warnings;
use utf8;

package Joplin::Base;

use Joplin::API;
use Carp;
use overload '""' => 'title';

# _wrap takes the supplied hash and wraps it in a new object.
#
# The api parameter is mandatory if this method is invoked from a
# class.

sub _wrap {
    my ( $pkg, $init, $api ) = @_;
    if ( ref($pkg) ) {
	$api = $pkg->api;
	$pkg = ref($pkg);
    }
    bless { %$init, _api => $api }, $pkg;
}

# Returns the low-level Joplin::API object.

sub api :lvalue {
    $_[0]->{_api};
}

# Checks if the Joplin API server can be reached.

sub ping {
    $_[0]->api->ping;
}

# Converts a timestamp readable ISO-8601 format.
# Note that joplin maintains times in milliseconds.

sub iso8601date {
    my ( $self, $time ) = @_;
    $time = @_ >= 2 ? $time/1000 : time;
    my @tm = localtime($time);
    sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
             1900+$tm[5], 1+$tm[4], @tm[3,2,1,0] );
}

################ Property Setter/Getters ################

# Gets the value of a readonly property.

sub _get_property {
    my ( $self, $name ) = @_;
    if ( @_ >= 3 ) {
	croak("Joplin: Property '$name' is read-only");
    }
    $self->{$name};
}

# Gets the lvalue of a property.
# With additional argument: modifies the property.

sub _set_get_property :lvalue {
    my ( $self, $name ) = splice( @_, 0, 2 );
    if ( @_ == 1 ) {
	$self->{$name} = $_[0];
    }
    $self->{$name};
}

# Sets up the property handlers for readonly and readwrite properties.

sub _set_property_handlers {
    my ( $pkg ) = @_;
    ( my $type = lc $pkg ) =~ s/^.*:://;

    no strict 'refs';
    foreach ( @{ Joplin::API->properties( $type, "rw" ) } ) {
	my $attr = $_;		# lexical for closure
	*{$pkg.'::'.$_} = sub :lvalue {
	    splice( @_, 1, 0, $attr );
	    goto &_set_get_property;
	};
    }
    foreach ( @{ Joplin::API->properties( $type, "ro" ) } ) {
	my $attr = $_;		# lexical for closure
	*{$pkg.'::'.$_} = sub {
	    splice( @_, 1, 0, $attr );
	    goto &_get_property;
	};
    }
    *{$pkg.'::'.'properties'} = sub {
	my ( $self, $what ) = @_;
	my @res = @{ Joplin::API->properties( $type, $what ) };
	wantarray ? @res : \@res;
    };
}

1;
