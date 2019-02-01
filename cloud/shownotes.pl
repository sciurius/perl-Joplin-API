#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Mon Sep  3 10:45:33 2018
# Last Modified By: Johan Vromans
# Last Modified On: Fri Oct 12 11:14:53 2018
# Update Count    : 231
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'JoplinTools';
# Program name and version.
my ($my_name, $my_version) = qw( shownotes 0.02 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $verbose = 0;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

my $root = Joplin::Notebook->new( _title => "Root" );
my $res;

while ( @ARGV ) {
    my $file = shift;
    if ( -d $file ) {
	unshift( @ARGV, glob( "$file/*.md" ) );
	$res = { map { $_ => 1 } glob( "$file/.resource/*" ) };
	redo;
    }
    my $fd;
    unless ( open( $fd, '<:utf8', $file ) ) {
	warn("$file: $!\n");
	next;
    }

    my $raw = do { local $/; <$fd> };
    close($fd);

    $root->loadnote( $file, $raw );
}

print $root->to_string;

foreach ( @{ $root->resources } ) {
    if ( $res->{$_} ) {
	delete $res->{$_};
    }
    else {
	warn("Missing resource: $_\n");
    }
}
foreach ( keys %$res ) {
    warn("Unreferences resource: $_\n");
}

################ Subroutines ################


################ Modules ################

package Joplin;			################

package Joplin::Base;

sub new {
    my $pkg = shift;
    bless { @_ } => $pkg;
}

sub id     { $_[0]->{id} }
sub data   { $_[0]->{_data} }
sub title  { $_[0]->{_title} }
sub type   { $_[0]->{type_} }
sub parent_id { $_[0]->{parent_id} || '' }
sub root   { $_[0]->{_root} }

# Get or create parent.
sub parent {
    my ( $self ) = @_;
    my $pid = $self->parent_id;
    $self->root->notes->{$pid} //= Joplin::Notebook->new;
}

# Type dependent content loader. Internal.
sub load {
    my ( $self, $file, $data, $meta ) = @_;

    foreach (split( /\n/, $meta ) ) {
	if ( /^(.*?):\s*(.*)/ ) {
	    $self->{$1} = $2;
	}
    }
    $self->{_title} = $1 if $data =~ /^(.*)/;
    $self->{_data} = $data;
    $self->{_size} = length($data);

    if ( $self->root->notes->{$self->id} ) {
	while ( my($k,$v) = each(%$self) ) {
	    $self->root->notes->{$self->id}->{$k} = $v;
	}
    }
    else {
	$self->root->notes->{$self->id} = $self;
    }
    $self->parent->add($self) if $self->parent_id ne '';
    return $self;
}

# Stringification.
sub to_string {
    my ( $self ) = @_;
    my $res = ref($self);
    $res =~ s/^.*:://;
    $res .= ": " . $self->title;
    $res .= " (" . $self->{_size} . " bytes)" if defined $self->{_size};
    $res . "\n";
}

package Joplin::Notebook;	################

use parent -norequire => Joplin::Base::;

sub new {
    shift->SUPER::new( type_ => 2,
		       _notes => {},
		       _resources => [],
		       _children => [],
		       @_ );
}

sub add {
    my ( $self, $note ) = @_;
    push( @{ $self->{_children} }, $note );
}

sub get_type {
    my ( $self, $raw ) = @_;
    my ( $data, $meta ) = $raw =~ /^(.*)\n\n((?:[^\n]+\n)+[^\n]+)\z/s;
    my $type; ( $type ) = $meta =~ m/^type_:\s+(\d+)\z/m;
    wantarray ? ( $type, $data, $meta ) : $type;
}

my @notebjects;			# STATIC

# This is the one and only method to add a note (file) to the notebook.
sub loadnote {
    my ( $self, $file, $data ) = @_;

    unless (defined $data ) {
	my $fd;
	unless ( open( $fd, '<:utf8', $file ) ) {
	    warn("$file: $!\n");
	    return;
	}
	$data = do { local $/; <$fd> };
    }

    my $meta;
    my $type;
    ( $type, $data, $meta ) = $self->get_type($data);
    unless ( defined $type ) {
	warn("$file: No type?\n");
	return;
    }

    @notebjects =
      qw( Unknown Note Notebook Unknown Image
	  Unknown Unknown Unknown Unknown Key )
	unless @notebjects;

    my $handler = $notebjects[$type];
    if ( !defined($handler) || $handler eq 'Unknown' ) {
	warn("$file: Unhandled type [$type] -- skipped\n");
	return;
    }

    $handler = 'Joplin::' . $handler;
    my $new = $handler->new( _root => $self )->load( $file, $data, $meta );
    $self->add($new) if $new->parent_id eq '';
    push( @{ $self->{_resources} }, $new->{_resource} )
      if $new->{_resource};

    return $new;
}

sub children {
    my ( $self ) = @_;
    wantarray ? @{ $self->{_children} } : $self->{_children};
}

# For root notebooks: *all* the notes in the tree, by id.
sub notes {
    $_[0]->{_notes};
}

sub resources {
    $_[0]->{_resources};
}

sub titlesort { lc($a->title) cmp lc($b->title) }

sub to_string {
    my ( $self ) = @_;
    my $res = "  ";
    foreach ( sort titlesort $self->children ) {
	$res .= $_->to_string;
    }
    $res =~ s/\n/\n  /g;
    $res =~ s/\n  \z/\n/;
    ref($self) =~ s/^.*:://r . ": " . $self->title . "\n" . $res;
}

package Joplin::Note;		################

use parent -norequire => Joplin::Base::;

sub new {
    shift->SUPER::new( type_ => 1, @_ );
}

package Joplin::Image;		################

use parent -norequire => Joplin::Base::;

sub new {
    shift->SUPER::new( type_ => 4, @_ );
}

sub load {
    my ( $self, $file, $data, $meta ) = @_;
    $self->SUPER::load( $file, $data, $meta );
    my $res = $file;
    $res =~ s;(/[0-9a-f]{32})\.md$;/.resource$1;;
    unless ( -e $res ) {
	warn("$file: No resource [$res]?\n");
    }
    else {
	$self->{_resource} = $res;
    }
    return $self;
}

sub to_string {
    my ( $self ) = @_;
    my $res = ref($self) =~ s/^.*:://r . ": ";
    $res .= $self->{mime} . " (" . (-s $self->{_resource}) . " bytes)\n";
    return $res;
}

package main;

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions('ident'	=> \$ident,
		   'verbose'	=> \$verbose,
		   'trace'	=> \$trace,
		   'help|?'	=> \$help,
		   'man'	=> \$man,
		   'debug'	=> \$debug)
	  or $pod2usage->(2);
    }
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
}

__END__

################ Documentation ################

=head1 NAME

shownotes - reads a dir with notes and shows a summary

=head1 SYNOPSIS

sample [options] [dir | file ...]

 Options:
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.

=item I<file>

The input file(s) to process, if any.

=back

=head1 DESCRIPTION

B<This program> will read the Joplin notes in the given directory and
produce a symmary.

=cut
