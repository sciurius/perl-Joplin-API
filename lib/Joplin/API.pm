#! perl

use strict;
use warnings;
use utf8;

package Joplin::API;

use JSON;
use Carp;
use Data::Dumper;

our $VERSION = "0.01";

=head1 NAME

Joplin::API - Access methods for the Joplin REST API.

=head1 SYNOPSIS

    use Joplin::API;

    my $api = Joplin::API->new( token => "YOUR KEY HERE" );
    my $res = $api->get_folders;
    foreach ( @$res ) {
        print( $_->{id}, " ", $_->{title}, "\n");
    }

=head1 DESCRIPTION

Joplin is a free, open source note taking and to-do application, which
can handle a large number of notes organised into notebooks. The notes
are searchable, can be copied, tagged and modified either from the
applications directly or from your own text editor. The notes are in
Markdown format.

Clients exist for Linux, Windows and OS/X desktop systems, and for
Android and iOS devices. Notes can be synchronized across clients.

A running desktop client can also act as an API server, giving access
to the notes database,

B<Joplin::API> provides a set of methods to access such a running Joplin
API server.

See L<https://joplin.cozic.net/> for general information on Joplin.

The API is described in L<https://joplin.cozic.net/api/>.

=head1 METHODS

B<Important:> All methods will throw an exception in case of errors.

All methods will return a property hash, or a reference to an array of property hashes, except:

=over 3

=item *

The C<find_...> methods will return an array of property hashes in
list context, and a reference to this array in scalar context.

=item *

The C<delete_...> methods will return true if successful.

=item *

Method C<ping> returns the identification string from the Joplin
server, usually C<JoplinClipperServer>

=back

=head2 new

Returns a new API object.

    $api = Joplin::API->new( token => $apikey );

Initial arguments:

=over 4

=item host

The name of the host running the Joplin API server. Default is the
local system.

=item port

The port the Joplin API server listens on. Default is C<41184>.

=item server

The complete connection string, e.g. C<http://localhost:41184>.

This is derived from C<host> and C<port>.

=item token

The Joplin API access token.

=item apikey

Alternative name for C<token>.

=back

=cut

sub new {
    my ( $pkg, %init ) = @_;
    my $self = bless { %init }, $pkg;

    if ( $self->{host} ) {
	$self->{port} ||= 41184;
	$self->{server} = "http://" . $self->{host} . ":" . $self->{port};
    }
    $self->{apikey} //= delete $self->{token};

    return $self;
}

=head2 set_server

Sets the name of the Joplin API server.

    $api->set_server($server);

=cut

sub set_server {
    my ( $self, $server ) = @_;
    $self->{server} = $server;
}

=head2 get_server

Returns the name of the Joplin API server.

    $server = $api->get_server;

=cut

sub get_server {
    my ( $self ) = @_;
    $self->{server};
}

=head2 set_apikey

Sets the Joplin API access token.

    $api->set_apikey($token);

C<set_token> is an alternative name for the same method.

=cut

sub set_apikey {
    my ( $self, $apikey ) = @_;
    $self->{apikey} = $apikey;
}
*set_token = \&set_apikey;

=head2 get_apikey

Returns the Joplin API access token.

    $api->set_apikey($token);

C<get_token> is an alternative name for the same method.

=cut

sub get_apikey {
    my ( $self ) = @_;
    $self->{apikey};
}
*get_token = \&get_apikey;

=head2 set_debug

Enables numerous debugging messages.

    $api->set_debug($state);

=cut

sub set_debug {
    my ( $self ) = @_;
    $self->{debug} = @_ == 1 ? 1 : $_[1];
}

################ Folders ################

=head1 FOLDER METHODS

=head2 get_folders

Returns an array with folder info.

    $res = $api->get_folders;

Each element is a hash containing selected folder properties.

=cut

sub get_folders {
    my ( $self ) = @_;
    $self->query( "get", "/folders" );
}

=head2 get_folder

Returns a hash containing the folder properties for a specific folder.

    $res = $api->get_folder($folder_id);

=cut

sub get_folder {
    my ( $self, $folder_id ) = @_;
    $folder_id
      ? $self->query( "get", "/folders/$folder_id" )
      : { id => 0 };
}

=head2 get_folder_notes

Returns an array with notes info for all the notes in this folder.

    $res = $api->get_folder_notes($folder_id);

Each element is a hash containing note properties.

=cut

sub get_folder_notes {
    my ( $self, $folder_id ) = @_;
    $folder_id
      ? $self->query( "get", "/folders/$folder_id/notes" )
      : $self->get_notes;
}

=head2 create_folder

Creates a new folder with the given title and, optional, properties.

    $res = $api->create_folder($title, parent_id => $parent_id );

Properties:

=over 4

=item title

The name (title) of the folder. Overrides the C<$title> argument.

=item parent_id

The id of the parent folder, if any.

=back

Returns a hash containing the properties of the new folder.

=cut

sub create_folder {
    my ( $self, $title, %args ) = @_;

    my $data = {};
    for ( qw( title parent_id ) ) {
	$data->{$_} = delete $args{$_} if exists $args{$_};
    }
    $data->{title} //= $title;
    croak( "Joplin::API: Unhandled properties in create_folder: " .
	   join(" ", sort keys %args) ) if %args;

    $self->query( "post", "/folders", $data );
}

=head2 update_folder

Updates the folder with new property values.

    $res = $api->update_folder($folder_id, title => $new_title);

Properties:

=over 4

=item title

The name (title) of the folder.

=item parent_id

The id of the parent folder.

=back

Returns a hash containing the properties of the new folder.

=cut

sub update_folder {
    my ( $self, $folder_id, %args ) = @_;

    my $data = {};
    for ( qw( title parent_id ) ) {
	next unless exists $args{$_};
	$data->{$_} = delete $args{$_};
    }
    croak( "Joplin::API: Unhandled properties in update_folder: " .
	   join(" ", sort keys %args) ) if %args;

    $self->query( "put", "/folders/$folder_id", $data );
}

=head2 delete_folder

Deletes the folder.

    $res = $api->delete_folder($folder_id);

Returns true if successful.

=cut

sub delete_folder {
    my ( $self, $folder_id ) = @_;
    $self->query( "delete", "/folders/$folder_id" );
}

=head2 find_folders

Finds folders by name.

    $res = $api->find_folders($pattern);

The argument C<$pattern> must be a string or a pattern. If a string,
it performs a case insensitive search on the name of the folder. A
pattern can be used for more complex matches.

Returns a (possibly empty) array of hashes with folder info if successful.

=cut

sub find_folders {
    croak("Joplin find_folders requires an argument") unless @_ == 2;
    my ( $self, $pat, $folders ) = @_;

    $folders //= $self->get_folders;

    my $folder;
    unless ( ref($pat) && ref($pat) eq "Regexp" ) {
	$pat = qr/^$pat$/i;	# case insens
    }

    # Recursive search through hierarchy.
    $self->__find_folders( $pat, $folders );
}

sub __find_folders {
    my ( $self, $pat, $folders ) = @_;
    my @res;
    foreach my $folder ( @$folders ) {
	if ( exists $folder->{children} ) {
	    my $folders = $self->__find_folders( $pat, $folder->{children} );
	    if ( $folders ) {
		push( @res, @$folders );
	    }
	}
	push( @res, { %$folder } ) if $folder->{title} =~ $pat;
    }

    return wantarray ? @res : \@res;
}

sub find_folder_notes {
    my ( $self, $folder_id, $pat ) = @_;
    croak("Joplin::API: find_folder_notes requires an argument")
      unless defined $pat;
    $self->find_folders( $pat, $self->get_folder_notes($folder_id) );
}

################ Notes ################

=head1 NOTE METHODS

=head2 get_notes

Returns an array with notes info.

    $res = $api->get_notes;

Each element is a hash with note properties.

=cut

sub get_notes {
    my ( $self ) = @_;
    $self->query( "get", "/notes/" );
}

=head2 get_note

Gets the data for a specific note.

    $res = $api->get_note($note_id);

Returns a hash with note properties.

=cut

sub get_note {
    my ( $self, $note_id ) = @_;
    $self->query( "get", "/notes/$note_id" );
}

=head2 get_note_tags

Returns an array with tags info for a specific note.

    $res = $api->get_note_tags($note_id);

Each element is a hash with tag properties.

=cut

sub get_note_tags {
    my ( $self, $note_id ) = @_;
    $self->query( "get", "/notes/$note_id/tags" );
}

=head2 create_note

Creates a new note with the given title, body, parent_id and,
optional, other properties.

    $res = $api->create_note($title, $body, $parent_id, is_todo => 1 );

Properties:

=over 4

=item author

The name of the note's author.

=item source_url

The source URL for the note, if any.

=item tags

A list of comma separated tag names.

=item is_todo

The note is a TODO.

=back

Returns a hash containing the properties of the new folder.

=cut

sub create_note {
    my ( $self, $title, $body, $parent_id, %args ) = @_;
    my $data = { title     => $title,
		 body      => $body,
		 parent_id => $parent_id };
    for ( qw( author source_url tags is_todo ) ) {
	$data->{$_} = delete $args{$_} if exists $args{$_};
    }
    croak( "Joplin::API: Unhandled properties in create_note: " .
	   join(" ", sort keys %args) ) if %args;

    $self->query( "post", "/notes/", $data );
}

=head2 update_note

Updates an existing note with new properties.

    $res = $api->update_note($note_id, title => $new_title );

Properties:

=over 4

=item title

The new title for the note.

=item body

New markdown content for the note.

=item parent_id

Moves the note the another folder.

=item author

The name of the note's author.

=item source_url

The source URL for the note, if any.

=item is_todo

The note is a TODO.

=item todo_due

A timestamp when the TODO must be completed.

The timestamp is epoch time in milliseconds.

=item todo_completed

A timestamp when the TODO was completed.

=back

Returns a hash containing the properties of the new folder.

=cut

sub update_note {
    my ( $self, $note_id, %args ) = @_;
    my $data = {};
    for ( qw( title body parent_id author source_url
	      is_todo todo_due todo_completed ) ) {
	$data->{$_} = delete $args{$_} if exists $args{$_};
    }
    croak( "Joplin::API: Unhandled properties in update_note: " .
	   join(" ", sort keys %args) ) if %args;
    # Only works with put.
    $self->query( "put", "/notes/$note_id", $data );
}

=head2 delete_note

Deletes the note.

    $res = $api->delete_note($note_id);

Returns true if successful.

=cut

sub delete_note {
    my ( $self, $note_id ) = @_;
    $self->query( "delete", "/notes/$note_id" );
}

=head2 find_notes

Finds notes by name.

    $res = $api->find_notes($pattern);

The argument C<$pattern> must be a string or a pattern. If a string,
it performs a case insensitive search on the name of the note. A
pattern can be used for more complex matches.

Returns a (possibly empty) array of hashes with note info if successful.

=cut

sub find_notes {
    splice( @_, 1, 0, "notes" );
    goto &find_selected;
}


################ Tags ################

=head1 TAG METHODS

=head2 get_tag

Gets the data for a specific tag.

    $res = $api->get_tag($tag_id);

Returns a hash with tag properties.

=cut

sub get_tag {
    my ( $self, $tag_id ) = @_;
    $self->query( "get", "/tags/$tag_id" );
}

=head2 get_tags

Returns an array of data for all tags.

    $res = $api->get_tags;

Each element is a hash with tag properties.

=cut

sub get_tags {
    my ( $self ) = @_;
    $self->query( "get", "/tags" );
}

=head2 create_tag

Creates a new tag. Note that Joplin downcases tag titles.

    $res = $api->create_tag($title);

Returns a hash with tag properties.

=cut

sub create_tag {
    my ( $self, $title ) = @_;
    my $data = { title => lc $title };

    $self->query( "post", "/tags", $data );
}

=head2 update_tag

Updates the title for a specific tag.

    $res = $api->update_tag($tag_id);

Returns a hash with updated tag properties.

=cut

sub update_tag {
    my ( $self, $tag_id, $title ) = @_;
    my $data = { title => lc $title };
    $self->query( "put", "/tags/$tag_id", $data );
}

=head2 delete_tag

Deletes a specific tag.

   $res = $api->delete_tag($tag_id);

Returns true if successful.

=cut

sub delete_tag {
    my ( $self, $tag_id ) = @_;
    $self->query( "delete", "/tags/$tag_id" );
}

=head2 get_tag_notes

Returns an array with data for all notes that have a specific tag.

    $res = $api->get_tag_notes($tag_id);

Each element is a hash with note properties.

=cut

sub get_tag_notes {
    my ( $self, $note_id ) = @_;
    $self->query( "get", "/tags/$note_id/notes" );
}

=head2 create_tag_note

Associate a tag with a note.

    $res = $api->create_tag_note( $tag_id, $note_id );

Returns a hash describing the link between the tag and the note.

=cut

sub create_tag_note {
    my ( $self, $tag_id, $note_id ) = @_;
    my $data = { id => $note_id };
    $self->query( "post", "/tags/$tag_id/notes", $data );
}

=head2 delete_tag_note

Deletes the association of the tag with the note.

    $res = $api->delete_tag_note( $tag_id, $note_id );

Returns true if successful.

=cut

sub delete_tag_note {
    my ( $self, $tag_id, $note_id ) = @_;
    $self->query( "delete", "/tags/$tag_id/notes/$note_id" );
}

=head2 find_tags

Finds tags by name.

    $res = $api->find_tags($pattern);

The argument C<$pattern> must be a string or a pattern. If a string,
it performs a case insensitive search on the name of the tag. A
pattern can be used for more complex matches.

Note that tag names (titles) are downcased by Joplin. Searching with a
pattern that requires uppercase characters will never succeed.

Returns a (possibly empty) array of hashes with tag info if successful.

=cut

sub find_tags {
    splice( @_, 1, 0, "tags" );
    goto &find_selected;
}

sub find_tag_notes {
}


################ Resources ################

=head1 RESOURCE METHODS

=head2 get_resource

Gets info for a specific resource.

    $res = $api->get_resource($res_id);

Returns a hash with resource properties.

=cut

sub get_resource {
    my ( $self, $resource_id ) = @_;
    $self->query( "get", "/resources/$resource_id" );
}

=head2 get_resources

Returns an array with info for all resources.

    $res = $api->get_resources;

Each element is a hash with resource properties.

=cut

sub get_resources {
    my ( $self ) = @_;
    $self->query( "get", "/resources" );
}

=head2 create_resource

Creates a new resource.

    $res = $api->create_resource( $file, title => $title );

The named file must be accessible and its content will be copied to
the resource.

Properties:

=over 4

=item title

The title for this resource. Defaults to the file name.

=item mime

The mime type for this resource. A suitable default will be guessed.

=back

Returns the properties for the new resource.

=cut

sub create_resource {
    my ( $self, $file, %args ) = @_;

    croak("Joplin::API: Resource $file not found")
      unless -e -s -r $file;

    my $data = { props => { title => $file } };
    for ( qw( title mime ) ) {
	$data->{props}->{$_} = delete $args{$_} if exists $args{$_};
    }
    croak( "Joplin::API: Unhandled properties in create_resource: " .
	   join(" ", sort keys %args) ) if %args;

    $data->{data} = $file;

    $self->query( "post+", "/resources", $data );
}

=head2 update_resource

Updates the properties of the resource.

    $res = $api->update_resource( $res_id, title => $title );

Properties:

=over 4

=item title

The new title for the resource.

=back

Returns a hash with updated properties.

=cut

sub update_resource {
    my ( $self, $resource_id, %args ) = @_;
    my $data = {};
    for ( qw( title mime ) ) {
	$data->{$_} = delete $args{$_} if exists $args{$_};
    }
    croak( "Joplin::API: Unhandled properties in update_resource: " .
	   join(" ", sort keys %args) ) if %args;

    $self->query( "put", "/resources/$resource_id", $data );
}

=head2 fetch_resource

Fetches a resource.

   $data = $api->fetch_resource($res_id);

Returns the raw data for the resource if successful.

=cut

sub fetch_resource {
    my ( $self, $resource_id ) = @_;
    $self->query( "get", "/resources/$resource_id/file", undef, "raw" );
}

=head2 delete_resource

Deletes a resource.

    $res = $api->delete_resource($res_id);

Returns true if successful.

=cut

sub delete_resource {
    my ( $self, $resource_id ) = @_;
    $self->query( "delete", "/resources/$resource_id" );
}

################ Low level ################

=head1 MISCELLANEOUS METHODS

=head2 ping

Checks whether the API server is accessible.

    $status = $api->ping

Returns true if successful.

=cut

sub ping {
    my ( $self ) = @_;
    $self->query( "get", "/ping", undef, "raw" );
}

=head2 query

This is the API communication handler used internally by all methods.

No user servicable parts inside.

=cut

use LWP::UserAgent;

sub query {
    my ( $self, $method, $path, $data, $raw ) = @_;

    croak("Joplin::API: Unsupported query path: $path")
      unless $path =~ m;^/(?:notes|folders|tags|resources|ping)(?:/|$);;

    my $ua = $self->{ua} ||= LWP::UserAgent->new( timeout => 10 );
    my $pp = $self->{pp} ||= JSON->new->utf8;

    $path = $self->{server} . $path;
    $path .= "?token=" . $self->{apikey} unless $path eq "/ping";

    warn( uc($method), " $path" ) if $self->{debug};

    my $res;
    if    ( $method eq "get" || $method eq "delete" ) {
	croak("Joplin::API: $method query doesn't take data") if $data;
	$res = $ua->$method($path);
	if ( $raw ) {
	    return undef unless $res->is_success;
	    return $res->decoded_content;
	}
    }
    elsif ( $method eq "put" || $method eq "post" ) {
	croak("Joplin::API: $method query requires data") unless $data;
	warn(Dumper($data)) if $self->{debug};
	$res = $ua->$method( $path, Content => $pp->encode($data) );
    }
    elsif ( $method eq "post+" ) {
	croak("Joplin::API: $method query requires data") unless $data;
	$res = $ua->post( $path,
			  Content_Type => 'form-data',
			  Content => [ data => [ $data->{data} ],
				       props => $pp->encode($data->{props}),
				     ] );
    }
    else {
	croak("Joplin::API: Unsupported query method: $method");
    }

    warn($res->decoded_content) if $self->{debug};
    unless ( $res->is_success ) {
	return 1 if $res->status_line =~ /500 OK/;
	croak( "Joplin::API: " . $res->status_line )
    }
    return $pp->decode($res->decoded_content);
}

sub find_selected {
    my ( $self, $what, $pat, $list ) = @_;
    croak("Joplin::API: find_$what requires an argument") unless defined $pat;
    $what = "get_$what";
    $list //= $self->$what;

    unless ( ref($pat) && ref($pat) eq "Regexp" ) {
	$pat = qr/^.*$pat/i;	# case insens
    }

    my @res;
    foreach my $item ( @$list ) {
	push( @res, { %$item } ) if $item->{title} =~ $pat;
    }

    return wantarray ? @res : \@res;
}

=head1 LICENSE

Copyright (C) 2019, Johan Vromans

This module is free software. You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

1;
