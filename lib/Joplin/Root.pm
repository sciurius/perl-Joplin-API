#! perl

use strict;
use warnings;
use utf8;

package Joplin::Root;

use Carp;

use parent qw(Joplin::Folder);

use Joplin::Note;
use Joplin::Tag;

=head1 METHODS

=head2 new

=cut

sub new {
    my ( $pkg, %init ) = @_;
    my $self = bless { id => '', parent_id => '',
		       _api => Joplin::API->new(%init) }, $pkg;
    return $self;
}


=head2 find_notes

Finds notes by name or pattern.

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

    unless ( !$pat || ref($pat) eq "Regexp" ) {
	$pat = qr/^$pat$/i;	# case insens
    }

    my @res;
    foreach ( @{ $self->api->get_notes } ) {
	next unless $recurse || $_->{parent_id} eq '';
	next if $pat && $_->{title} !~ $pat;
	push( @res, Joplin::Note->_wrap( $_, $self->api ) );
    }

    return wantarray ? @res : \@res;
}

=head2 find_folders

Finds folders by name or pattern.

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
    my $list = $recurse
      ? $self->api->get_folders_recursive
      : $self->api->get_folders;
    foreach my $f ( @$list ) {
	next if $pat && $f->{title} !~ $pat;
	push( @res, Joplin::Folder->_wrap( $f, $self->api ) );
    }

    return wantarray ? @res : \@res;
}

=head2 find_tags

Finds matching tags.

    @res = $root->find_tags("my tag");

Returns a possible empty) array of Joplin::Tag objects.

=cut

sub find_tags {
    my ( $self, $pat ) = @_;

    my @res = map { Joplin::Tag->_wrap( $_, $self->api ) }
      @{ $self->api->find_tags($pat) };
    wantarray ? @res : \@res;
}

################ Inhibits ################

sub delete {
    croak("Joplin: Cannot delete the root folder!");
}

sub update {
    croak("Joplin: Cannot update the root folder!");
}

sub refresh {
    croak("Joplin: Cannot refresh the root folder!");
}

################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
