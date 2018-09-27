#!/usr/bin/perl -w

# Add notes to Joplin using the Web Clipper API.
# See https://discourse.joplin.cozic.net/t/web-clipper-is-now-available-beta-feature/154/37

# Author          : Johan Vromans
# Created On      : Wed Sep 26 13:44:45 2018
# Last Modified By: Johan Vromans
# Last Modified On: Wed Sep 26 23:48:18 2018
# Update Count    : 105
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Encode;

# Package name.
my $my_package = 'JoplinTools';
# Program name and version.
my ($my_name, $my_version) = qw( addnote 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $title;
my $parent;
my $host = "http://127.0.0.1";
my $port;
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

use LWP::UserAgent;
use JSON;
use MIME::Base64;

my $pp = JSON->new->utf8;
my $ua = LWP::UserAgent->new;

################ The Process ################

my $author = (getpwuid($<))[6];

# Find port, in case it differs from default.
$port ||= find_port();
$parent = find_folder($parent);

my $data;
my $file = $ARGV[0];

if ( defined($file) && !$title ) {
    ( $title = $file ) =~ s;^.*/;;
}

my $content = { parent_id  => $parent,
		title      => $title,
		defined($file) ? ( source_url => $file ) : (),
		author     => $author,
	      };

if ( $file =~ /\.(jpe?g|gif|png)$/ ) {			# image
    my $mime = $1;
    $mime = "jpeg" if $mime eq "jpg";
    $mime = "image/jpeg";
    open( my $fd, '<:raw', $file )
      or die("$file: $!\n");
    my $data = encode_base64( do { local $/; <$fd> } );
    close($fd);

    $content->{body} = $file;
    $content->{image_data_url} = "data:$mime;base64,$data";
}
elsif ( $file =~ /^https?:/ ) {
    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    my $res = $ua->get($file);
    unless ( $res->is_success ) {
	die("$file: ", $res->status_line, "\n");
    }
    my $data = $res->decoded_content;
    if ( $data =~ /^<(!doctype html|html)/i ) {
	$content->{body_html} = $data;
    }
    else {
	$content->{body} = $data;
    }
    $content->{base_url} = $file;
}
else {
    my $data = do { local $/; <> };
    if ( $data =~ /^<html/i ) {
	$content->{body_html} = $data;
    }
    else {
	$content->{body} = $data;
    }
}

my $res = $ua->post( "$host:$port/notes",
		     Content => $pp->encode($content) );
unless ( $res->is_success ) {
    die( $res->status_line );
}

################ Subroutines ################

sub find_port {
    $ua->timeout(1);
    for ( 41184 .. 41194 ) {
	my $res = $ua->get("$host:$_/ping");
	if ( $res->is_success ) {
	    return $_;
	}
    }
    die("Cannot find the Joplin server. Is it running?\n");
}

sub find_folder {
    my ( $pat ) = @_;

    $ua->timeout(3);
    my $res = $ua->get("$host:$port/folders");
    unless ( $res->is_success ) {
	die( $res->status_line );
    }
    my $folders = $pp->decode( $res->decoded_content );

    my $folder;
    if ( $pat ) {
	if ( $pat =~ m;^/(.*); ) {
	    $pat = $1;
	}
	else {
	    $pat = qr/^.*$pat/i;	# case insens substr
	}
	$folder = _find_folder( $pat, $folders );
    }

    return $folder || _find_folder( "Imported Notes", $folders );
}

sub _find_folder {
    my ( $pat, $folders ) = @_;
    my $folder;
    foreach ( @$folders ) {
	next unless $_->{type_} == 2;
	if ( exists $_->{children} ) {
	    $folder = _find_folder( $pat, $_->{children} );
	    return $folder if $folder;
	}
	next unless $_->{title} =~ $pat;
	$folder = $_->{id};
	last;
    }

    return $folder;
}

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
	GetOptions('parent=s'	=> sub { $parent = decode_utf8($_[1]) },
		   'title=s'	=> sub { $title  = decode_utf8($_[1]) },
		   'host=s'	=> sub { $host   = decode_utf8($_[1]) },
		   'port=i'	=> \$port,
		   'ident'	=> \$ident,
		   'verbose+'	=> \$verbose,
		   'quiet'	=> sub { $verbose = 0 },
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

addnote - add a note to Joplin using the web API

=head1 SYNOPSIS

makenote [options] [file ...]

 Options:
   --parent=XXX		note parent (defaults to "Imported Notes")
   --title=XXX		title (optional)
   --host=XXX		the host running the Joplin server
   --port=NNN		Joplin server port, if not default
   --ident		shows identification
   --quiet		runs quietly
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information

=head1 OPTIONS

=over 8

=item B<--parent=>I<XXX>

Specifies the parent for the note or folder.

The argument is used for case insensitive substring search
on folder titles. If it starts with a C</>, it is interpreted as a
regular expression pattern to be matched against the folder titles.

=item B<--host=>I<NNN>

The host where the Joplin server is running.
Default is the local host.

=item B<--port=>I<XXX>

The port where the Joplin server is listening to.
Default port is 41184.

=item B<--title=>I<XXX>

Specifies the title for the note or folder.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.

=item B<--quiet>

Runs quietly.

=item I<file>

The input file to process, if any. For images, the file name must
appear on the command line.

=back

=head1 DESCRIPTION

B<This program> will add a note to a Joplin server running the web API.

=cut
