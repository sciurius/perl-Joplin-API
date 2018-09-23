#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Mon Sep 17 10:45:33 2018
# Last Modified By: Johan Vromans
# Last Modified On: Mon Sep 17 14:30:39 2018
# Update Count    : 73
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

# Package name.
my $my_package = 'JoplinTools';
# Program name and version.
my ($my_name, $my_version) = qw( shownotes 0.01 );

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

my $tree;


my $nb = Joplin::Notebook->new;
foreach my $file ( @ARGV ) {
    my $fd;
    unless ( open( $fd, '<:utf8', $file ) ) {
	warn("$file: $!\n");
	next;
    }

    my $raw = do { local $/; <$fd> };
    close($fd);

    my $type = Joplin::Notebook::get_type($raw);
    if ( $type == 1 ) {		# note
	my $n = Joplin::Note->new;
	$n->load( $file, $raw );
	$nb->add($n);
    }
    elsif ( $type == 2 ) {	# folder
	my $n = Joplin::Notebook->new;
	$n->load( $file, $raw );
	$nb->add($n);
    }
    elsif ( $type == 9 ) {	# master key
    }
}

use DDumper; DDumper($nb);

#
#
#sub titlesort;
#
#foreach ( sort titlesort keys %$tree ) {
#    shownote($_);
#}

################ Subroutines ################

sub loadnote {
    my ( $file ) = @_;
    my $fd;
    unless ( open( $fd, '<:utf8', $file ) ) {
	warn("$file: $!\n");
	return;
    }

    my $data = do { local $/; <$fd> };
    my $meta;
    ( $data, $meta ) = $data =~ /^(.*)\n\n((?:[^\n]+\n)+[^\n]+)\z/s;
    my $type = $1 if $meta =~ m/^type_:\s+(\d+)\z/m;
    unless ( defined $type ) {
	warn("$file: No type?\n");
	return;
    }

    my $m;
    foreach (split( /\n/, $meta ) ) {
	if ( /^(.*?):\s*(.*)/ ) {
	    $m->{$1} = $2;
	}
    }
    die unless $m->{type_} == $type;
    $m->{_title} = $1 if $data =~ /^(.*)/;

    if ( $type == 1 ) {		# note
	my $parent = $m->{parent_id};
	push( @{ $tree->{$parent}->{_children} }, { _data => $data, %$m } );
    }
    elsif ( $type == 2 ) {	# folder
	my $parent = $m->{parent_id};
	$tree->{$m->{id}}->{_data} = $data;
	while ( my ( $k, $v ) = each(%$m) ) {
	    $tree->{$m->{id}}->{$k} = $v;
	}
    }
    else {
	warn("$file: Unhandled type $type -- skipped\n");
	return;
    }
}

sub titlesort { $tree->{$a}->{_title} cmp $tree->{$b}->{_title} }

sub shownote {
    print $tree->{$_}->{_title}, "\n";
    if ( $tree->{$_}->{_children} ) {
	foreach ( sort { $a->{_title} cmp $b->{_title} } @{ $tree->{$_}->{_children} } ) {
	    print $_->{_title}, "\n";
	}
    }
}

################ Modules ################

package Joplin;

my $notes;

package Joplin::Base;

sub id     { $_[0]->{id} }
sub data   { $_[0]->{_data} }
sub title  { $_[0]->{_title} }
sub parent_id { $_[0]->{_parent_id} }
sub parent { $notes->{$_[0]->parent_id} }

package Joplin::Notebook;

sub new {
    my ( $pkg ) = shift;
    my $self = { @_ };
    $self->{_notes} //= [];
    bless $self, $pkg;
}

sub add {
    my ( $self, $note ) = @_;
    push( @{ $self->{_notes} }, $note );
}

sub notes {
    my ( $self ) = @_;
    wantarray ? @{ $self->{_notes} } : $self->{_notes};
}

sub get_type {
    my ( $raw ) = @_;
    my ( $data, $meta ) = $raw =~ /^(.*)\n\n((?:[^\n]+\n)+[^\n]+)\z/s;
    my $type; ( $type ) = $meta =~ m/^type_:\s+(\d+)\z/m;
    warn("TYPE: $type");
    wantarray ? ( $type, $data, $meta ) : $type;
}

package Joplin::Note;

our @ISA = ( 'Joplin::Base' );

sub new {
    my ( $pkg ) = shift;
    my $self = { @_ };
    bless $self, $pkg;
}

sub load {
    my ( $self, $file, $raw ) = @_;

    my ( $type, $data, $meta ) = Joplin::Notebook::get_type($raw);
    unless ( defined $type ) {
	warn("$file: No type?\n");
	return;
    }

    foreach (split( /\n/, $meta ) ) {
	if ( /^(.*?):\s*(.*)/ ) {
	    $self->{$1} = $2;
	}
    }
    die unless $self->{type_} == $type;
    $self->{_title} = $1 if $data =~ /^(.*)/;
    $self->{_data} = $data;
}

package Joplin::Folder;

our @ISA = ( 'Joplin::Base' );

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

sample - skeleton for GetOpt::Long and Pod::Usage

=head1 SYNOPSIS

sample [options] [file ...]

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

B<This program> will read the given input file(s) and do someting
useful with the contents thereof.

=cut
