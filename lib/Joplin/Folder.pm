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

our $TYPE = 2;			# node type
our @PROPERTIES;		# node properties

=head1 METHODS

=head2 get_notes

Gets the notes in this folder.

    $res = $folder->get_notes;

Returns an array with Joplin::Note objects.

=cut

sub get_notes {
    my ( $self ) = @_;
    [ map { bless { _api => $self->api, %$_ } => "Joplin::Note" }
        @{ $self->api->get_folder_notes( $self->id ) } ];
}

=head2 find_notes

Finds notes by name or pattern in this folder.

    $res = $folder->find_notes($pat);

Returns an array with Joplin::Note objects.

=cut

sub find_notes {
    my ( $self, $pat ) = @_;
    [ map { bless { _api => $self->api, %$_ } => "Joplin::Note" }
        @{ $self->api->get_folder_notes( $self->id, $pat ) } ];
}

=head2 find_folders

Finds folders by name or pattern in this folder.

    $res = $folder->find_folder($pat);

Returns an array with Joplin::Folder objects.
Currently only implemented for the root folder.

=cut

sub find_folders {
    my ( $self, $pat ) = @_;
    croak("Joplin: find_folders only implemented for the root folder")
      unless $self->is_root;
    [ map { bless { _api => $self->api, %$_ } => "Joplin::Folder" }
        @{ $self->api->find_folders($pat) } ];
}

=name2 create

=cut

sub create {
    my ( $self, $title, %args ) = @_;
    $args{parent_id} //= $self->id;
    bless { _api => $self->api,
	    %{ $self->api->create_folder( $title, %args ) } }
      => "Joplin::Folder";
}

=name2 delete

=cut

sub delete {
    my ( $self ) = @_;
    croak("Joplin: Cannot delete the root folder!") if $self->is_root;
    $self->api->delete_folder( $self->id );
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
    @PROPERTIES =
      qw( id parent_id title created_time updated_time
	  user_created_time user_updated_time
	  encryption_cipher_text encryption_applied );

    __PACKAGE__->_set_property_handlers(\@PROPERTIES);
}

1;
