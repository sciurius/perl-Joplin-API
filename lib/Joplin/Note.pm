#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Note;

use parent qw(Joplin::Base);

use Joplin::Tag;

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

=name2 add_tag

Adds a tag to the note.

    $tag = $note->add_tag("my tag");

Returns a Joplin::Tag object.

=cut

sub add_tag {
    my ( $self, $title, %args ) = @_;

    my $tag;

    unless ( ref($title) eq "Joplin::Tag" ) {
	$tag = $self->api->find_tags($title)->[0]
	  // $self->api->create_tag($title, %args);
	$tag = Joplin::Tag->_wrap($tag);
    }

    $self->api->create_tag_note( $tag->id, $self->id );
    return $tag;
}

=name2 delete_tag

Removes a tag from the note.

    $tag = $note->delete_tag("my tag");

Returns true upon success.

=cut

sub delete_tag {
    my ( $self, $tag ) = @_;

    unless ( ref($tag) eq "Joplin::Tag" ) {
	$tag = $self->api->find_tags($tag)->[0];
	return 1 unless defined $tag;
	$tag = Joplin::Tag->_wrap($tag);
    }

    $self->api->delete_tag_note( $tag->id, $self->id );
}

=name2 folder

Finds the parent forder of the note.

    $folder = $note->folder;

Returns a Joplin::Folder object.

=cut

sub folder {
    my ( $self ) = @_;

    if ( $self->parent_id eq '' ) {
	return Joplin::Folder->_wrap( { id => '' }, $self->api );
    }
    Joplin::Folder->_wrap( $self->api->get_folder( $self->parent_id ),
			   $self->api );
}

################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
