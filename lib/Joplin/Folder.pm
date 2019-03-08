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
use Joplin::Tag;

=head1 METHODS

=head2 find_notes

Finds notes by name or pattern in this folder.

    @res = $folder->find_notes($pattern);
    $res = $folder->find_notes($pattern);

The optional argument C<$pattern> must be a string or a pattern. If a
string, it performs a case insensitive search on the name of the note.
A pattern can be used for more complex matches. If the pattern is
omitted, all results are returned.

Returns a (possibly empty) array of Joplin::Note objects.

With a second, non-false argument, the search includes subfolders.

=cut

sub find_notes {
    my ( $self, $pat, $recurse ) = @_;

    my $res;
    if ( $recurse ) {
	foreach ( @{ $self->api->get_folders_recursive( $self->id ) } ) {
	    push( @$res,
		  @{ $self->api->find_folder_notes( $_->{id}, $pat ) } );
	}
    }
    else {
	$res = $self->api->find_folder_notes( $self->id, $pat );
    }

    $res = [ map { Joplin::Note->_wrap( $_, $self->api ) } @$res ];
    return wantarray ? @$res : $res;
}

=head2 find_folders

Finds folders by name or pattern in this folder.

    @res = $folder->find_folder($pattern);
    $res = $folder->find_folder($pattern);

The optional argument C<$pattern> must be a string or a pattern. If a
string, it performs a case insensitive search on the name of the note.
A pattern can be used for more complex matches. If the pattern is
omitted, all results are returned.

Returns a (possibly empty) array of Joplin::Folder objects.

With a second, non-false argument, the search includes subfolders.

=cut

sub find_folders {
    my ( $self, $pat, $recurse ) = @_;

    unless ( !$pat || ref($pat) eq "Regexp" ) {
	$pat = qr/^$pat$/i;	# case insens
    }

    my @res;
    my $list = $self->api->get_folders_recursive( $self->id );
    if ( $recurse ) {
	shift(@$list);
    }
    else {
	$list = [ grep { $_->{parent_id} eq $self->id } @$list ];
    }
    foreach my $f ( @$list ) {
	next if $pat && $f->{title} !~ $pat;
	push( @res, Joplin::Folder->_wrap( $f, $self->api ) );
    }

    return wantarray ? @res : \@res;
}

=name2 create_folder

Creates a new (sub)folder with the given name and optional properties.

    $new = $folder->create_folder("A SubFolder");

Returns a Joplin::Folder object for the new folder.

=cut

sub create_folder {
    my ( $self, $title, %args ) = @_;
    $args{parent_id} //= $self->id;
    Joplin::Folder->_wrap( $self->api->create_folder( $title, %args ),
			   $self->api );
}

=name2 create_note

Creates a new note with the given name and optional properties.

    $new = $folder->create_note("Title", "Content goes *here*");

Returns a Joplin::Note object for the new note.

=cut

sub create_note {
    my ( $self, $title, $content, %args ) = @_;
    Joplin::Note->_wrap( $self->api->create_note( $title, $content, $self->id, %args ),
			 $self->api );
}

=name2 delete

Deletes the current folder.

    $folder->delete;

Returns true if successful.

=cut

sub delete {
    my ( $self ) = @_;
    $self->api->delete_folder( $self->id );
}

=head2 update

Updates the properties of the folder to the server.

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
	  if #exists $self->properties("rw")->{$_} &&
	    defined($new->{$_}) && $new->{$_} ne $current->{$_};
	delete $new->{$_};
    }
    croak("Joplin: Unhandled properties in folder update: " .
	  join(" ", sort keys %$new) ) if %$new;
    my $res = $self->api->update_folder( $self->id, %$data );
    @$self{keys(%$res)} = values(%$res);
    $self;
}

=head2 refresh

Updates the folder to the server properties.

   $res = $folder->refresh

Returns the folder object with refreshed properties.

=cut

sub refresh {
    my ( $self ) = @_;
    my $new = $self->api->get_folder( $self->id );
    @$self{keys(%$new)} = values(%$new);
    $self;
}

=head2 is_root

Tests if this folder is the root folder.

    $status = $folder->is_root;

=cut

sub is_root { shift->isa('Joplin::Root') }

################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
