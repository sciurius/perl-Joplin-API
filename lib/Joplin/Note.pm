#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Note;

use parent qw(Joplin::Base);

=head2 update

Updates the properties of the note to the server.

    $res = $note->update;

Returns the note object with updated properties.

=cut

sub update {
    my ( $self ) = @_;
    my $current = $self->api->get_note( $self->id );
    my $new = { %$self };
    delete $new->{_api};
    my $data = {};
    foreach ( keys(%$current) ) {
	$data->{$_} = $new->{$_}
	  if #exists $self->properties("rw")->{$_} &&
	    defined($new->{$_}) && $new->{$_} ne $current->{$_};
	delete $new->{$_};
    }
    croak("Joplin: Unhandled properties in note update: " .
	  join(" ", sort keys %$new) ) if %$new;
    my $res = $self->api->update_note( $self->id, %$data );
    @$self{keys(%$res)} = values(%$res);
    $self;
}

=head2 refresh

Updates the note to the server properties.

   $res = $note->refresh

Returns the note object with refreshed properties.

=cut

sub refresh {
    my ( $self ) = @_;
    my $new = $self->api->get_note( $self->id );
    @$self{keys(%$new)} = values(%$new);
    $self;
}

=name2 delete

Deletes the current note.

    $note->delete;

Returns true if successful.

=cut

sub delete {
    my ( $self ) = @_;
    $self->api->delete_note( $self->id );
}

=name2 export

=cut

sub export {
    my ( $self, $filename ) = @_;
    open( my $fd, '>:utf8', $filename )
      or croak("Export: $filename [$!]");
    print $fd $self->{body_html} || $self->{body};
    close($fd);
}

################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
