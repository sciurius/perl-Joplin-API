#! perl

use strict;
use warnings;
use utf8;

=head1 Joplin::Folder

Joplin::Folder - Class for Joplin folders

=head1 SYNOPSIS

    # Connect to Joplin.
    $root = Joplin->connect( ... );

    # Find folder with name "Project". Assume there is only one.
    $prj = $root->find_folders("Project")->[0];

    $ Find the notes in this project that have "january" in the title.
    $notes = $prj->find_notes(qr/january/i);

=head1 DESCRIPTION

This class provides methods to deal with Joplin folders.

=cut

package Joplin::Folder;

use Carp;

use parent qw(Joplin::Base);

use Joplin::Note;

=head1 METHODS

=head2 get_notes

Gets the notes in this folder.

    $res = $folder->get_notes;

Returns an array with Joplin::Note objects.

=cut

sub get_notes {
    my ( $self ) = @_;
    my @res = map { bless { _api => $self->api, %$_ } => "Joplin::Note" }
      @{ $self->api->get_folder_notes( $self->id ) };
    wantarray ? @res : \@res;
}

=head2 find_notes

Finds notes by name or pattern in this folder.

    $res = $folder->find_notes($pat);

Returns an array with Joplin::Note objects.

=cut

sub find_notes {
    my ( $self, $pat ) = @_;
    my @res = map { bless { _api => $self->api, %$_ } => "Joplin::Note" }
        @{ $self->api->get_folder_notes( $self->id, $pat ) };
    wantarray ? @res : \@res;
}

=head2 find_folders

Finds folders by name or pattern in this folder.

    $res = $folder->find_folder($pat);

Returns an array with Joplin::Folder objects.

=cut

sub find_folders {
    my ( $self, $pat ) = @_;
    if ( $self->is_root ) {
	my @res = map { bless { _api => $self->api, %$_ } => "Joplin::Folder" }
	  @{ $self->api->find_folders($pat) };
	return wantarray ? @res : \@res;
    }
    $self->api->find_folders( $pat, $self->{children} // [] );
}

=name2 create_folder

Creates a new (sub)folder with the given name and optional properties.

    $new = $folder->create_folder("A SubFolder");

Returns a Joplin::Folder object for the new folder.

=cut

sub create_folder {
    my ( $self, $title, %args ) = @_;
    $args{parent_id} //= $self->id;
    bless { _api => $self->api,
	    %{ $self->api->create_folder( $title, %args ) } }
      => "Joplin::Folder";
}

=name2 create_note

Creates a new note with the given name and optional properties.

    $new = $folder->create_note("Title", "Content goes *here*");

Returns a Joplin::Note object for the new note.

=cut

sub create_note {
    my ( $self, $title, $content, %args ) = @_;
    bless { _api => $self->api,
	    %{ $self->api->create_note( $title, $content, $self->id, %args ) } }
      => "Joplin::Note";
}

=name2 delete

Deletes the current folder.

    $folder->delete;

Returns true if successful.

=cut

sub delete {
    my ( $self ) = @_;
    croak("Joplin: Cannot delete the root folder!") if $self->is_root;
    $self->api->delete_folder( $self->id );
}

=head2 update

Updates the properties of the folder.

    $res = $folder->update;

Returns the folder object with updated properties.

=cut

sub update {
    my ( $self ) = @_;
    my $current = $self->api->get_folder( $self->id );
    my $new = { %$self };
    delete $new->{_api};
    my $data = {};
    foreach ( keys(%$current) ) {
	$data->{$_} = $new->{$_}
	  if $_ =~ /^parent_id|title$/
	    && defined($new->{$_}) && $new->{$_} ne $current->{$_};
	delete $new->{$_};
    }
    croak("Joplin: Unhandled properties in folder update: " .
	  join(" ", sort keys %$new) ) if %$new;
    my $res = $self->api->update_folder( $self->id, %$data );
    @$self{keys(%$res)} = values(%$res);
    $self;
}

=head2 is_root

Tests if this folder is the root folder.

    $status = $folder->is_root;

=cut

sub is_root {
    ( $_[0]->id // '1' ) eq '';
}

################ Initialisation ################

BEGIN {
    my @rw =
      qw( id parent_id title
	  user_created_time user_updated_time );
    my @ro =
      qw( created_time updated_time
	  encryption_cipher_text encryption_applied );

    __PACKAGE__->_set_property_handlers( \@rw, \@ro );
}

1;
