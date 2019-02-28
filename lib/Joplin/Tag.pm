#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Joplin::Tag;

use parent qw(Joplin::Base);

use Joplin::Note;

=head1 METHODS

=head2 create

Creates a new tag.

    $tag = Joplin::Tag->create("my tag");

Returns a Joplin::Tag object.

=cut

sub create {
    my ( $pkg, $title, %args ) = @_;
    my $res = do { ... };
}

=head2 find_notes

Finds notes by name or pattern having this tag.

    @res = $tag->find_notes($pattern);
    $res = $tag->find_notes($pattern);

The optional argument C<$pattern> must be a string or a pattern. If a
string, it performs a case insensitive search on the name of the note.
A pattern can be used for more complex matches. If the pattern is
omitted, all results are returned.

Returns a (possibly empty) array of Joplin::Note objects.

=cut

sub find_notes {
    my ( $self, $pat ) = @_;
    my @res = map { Joplin::Note->_wrap( $_, $self->api ) }
      @{ $self->api->find_selected( $pat,
				    $self->api->get_tag_notes($self->id)
				   ) };
    wantarray ? @res : \@res;
}

=name2 delete

Deletes the current tag.

    $tag->delete

Returns true if successful.

=cut

sub delete {
    my ( $self ) = @_;
    $self->api->delete_tag( $self->id );
}


################ Initialisation ################

__PACKAGE__->_set_property_handlers;

1;
