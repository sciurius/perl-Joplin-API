#! perl

use strict;
use warnings;
use utf8;
use Carp;

=head1 NAME

Joplin - Interface to Joplin notes

=head1 SYNOPSIS

    # Connect to Joplin.
    $root = Joplin->connect( ... );

    # Find folder with name "Project". Assume there is only one.
    $prj = $root->find_folders("Project")->[0];

    $ Find the notes in the Project folder that have "january" in the title.
    $notes = $prj->find_notes(qr/january/i);

=head1 DESCRIPTION

This class handles connecting to the Joplin server.

=cut

package Joplin;

use Joplin::API;
use Joplin::Folder;

our $VERSION = "0.01";

=name1 METHODS

=head2 connect

Connects to the Joplin notes server.

    $root = Joplin->connect(%init);

Returns a Joplin::Folder object representing the root of all notes.

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

sub connect {
    my ( $pkg, %init ) = @_;
    my $self = Joplin::Folder->_wrap( { id => '' },
				      Joplin::API->new(%init) );
    return $self;
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
