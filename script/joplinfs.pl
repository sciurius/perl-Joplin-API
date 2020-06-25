#!/usr/bin/perl

# FUSE access to Joplin API.

# Author          : Johan Vromans
# Created On      : Tue Apr 14 21:17:43 2020
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jun 25 14:41:20 2020
# Update Count    : 362
# Status          : Unknown, Use with caution!

################ Common stuff ################

use 5.010001;
use strict;
use warnings;
use utf8;
use Carp ();
use FindBin;
use lib "$FindBin::Bin/../lib";

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = qw( joplinfs 0.02 );

# Establish some system capabilities.
system_capabilities();

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my $server = "http://localhost:27583";
my $apikey = "f21437609de3e09ad78dc90dd126d51eefc03bbc58a462f1f194a767a46f222c4b0c7cbfad7b7ea580e20c2f7d35bec94b639e974b1d660467840c1f46d77a9a";
my $prefix = "/joplin";
my $use_real_statfs;
my $pidfile;
my $logfile;
my $daemon = 1;
my $verbose = 1;		# verbose processing

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Extra options for Fuse.
my %extraopts = ( 'threaded' => 0, 'debug' => 0 );

# Process command line options.
app_options();

# Post-processing.
$prefix =~ s;/+$;;;
$prefix =~ s;^/*$;/;;
$trace |= ($debug || $test);

################ Presets ################

$SIG{'__WARN__'} = \&Carp::cluck if $debug;
binmode( STDOUT, ':utf8' );
binmode( STDERR, ':utf8' );

################ The Process ################

use Joplin;
use Fuse;
use POSIX qw( ENOTDIR  ENOENT ENOSYS   EEXIST   EPERM   EINVAL
	      O_RDONLY O_RDWR O_WRONLY O_APPEND O_CREAT setsid );

# We need a mount point that we can read/write to.
my ( $mountpoint) = @ARGV;
if ( ! -d -r -w -x $mountpoint ) {
    # Note that there may be a joplinfs already active...
    die( "$mountpoint: non-existent/accessible directory\n" );
}

# Connect to server.
my $root = Joplin->connect( server => $server,
			    apikey => $apikey,
			  );
unless ( defined $root ) {
    die( "Cannot connect to $server\n",
	 "Is the Joplin server running?\n" );
}
$root->api->set_debug($debug);

# Put ourselves in the background.
daemonize() if $daemon;

# Activate FUSE.
Fuse::main( mountpoint    => $mountpoint,
	    callbacks(),
	    %extraopts );

################ Callbacks ################

# System capabilities, determined by system_capabilities().
my $has_threads		  = 0;
my $has_Filesys__Statvfs  = 0;
my $use_lchown		  = 0;
my $has_mknod		  = 0;

use Encode;

my %fs;

# Map filenames to base.
# Filenames start with / relative to the mount point.
sub fixup {
    my ( $file ) = @_;
    $file = Encode::decode_utf8($file);
    Carp::cluck("Alien filename: $file")
      unless $file =~ s;^\Q$prefix\E(/|$);;;
    $file =~ s/\.md$//;
    return $file;
}

#### General callbacks.

sub jfs_getattr {
    my ( $file ) = @_;
    # warn("getattr: \"$file\"");

    # TODO This is to avoid the fuse fs to be overrun by gvfs monitors.
    return -ENOSYS if $file !~ m;^\Q$prefix\E(?:/|$);;

    $file = fixup($file);
    #return -ENOENT unless $file;
    warn("getattr: \"$file\"");
    my @list = ( 0, 0, 0040755, 1, 0+$<, 0+$(, 0, 0,
		 time, time-1000, time-2000, 512, 0 );

    my $res = find($file);
    return $res if $res < 0;
    if ( $res && @$res ) {
	if ( $res->[0]->isa('Joplin::Note') ) {
	    $list[ 2] = 0100644;
	    $list[ 9] = int( $res->[0]->updated_time / 1000 );
	    $list[10] = int( $res->[0]->created_time
			     // $res->[0]->user_created_time / 1000 );
	    if ( $file =~ /Sum$/ ) {
		$list[2] |= 020000;
	    }
	}
	elsif ( $res->[0]->isa('Joplin::Folder') ) {
	    $list[ 2] = 0040755;
	    $list[ 7] = $res->[0]->{note_count};
	}
    }
    else {
	return -ENOENT;
    }
    return @list;
}

sub jfs_getdir {
    my ( $dirname ) = @_;

    # TODO This is to avoid the fuse fs to be overrun by gvfs monitors.
    return -ENOENT if $dirname !~ m;^\Q$prefix\E(?:/|$);;

    $dirname = fixup($dirname);
    # TODO This is to avoid the fuse fs to be overrun by gvfs monitors.
    #return -ENOENT unless $dirname;
    warn("getdir: \"$dirname\"");

    my $res = find($dirname);
    return -ENOENT unless @$res && $res->[0]->isa('Joplin::Folder');
    my $f = $res->[0];

    my $r1 = $f->find_folders;
    my $r2 = $f->find_notes;

    my @files = map { $_->{title} } @$r1;
    push( @files, map { $_->{title} . ".md" } @$r2 );
    return ( @files, 0 );
}

#### Open/close callbacks.

sub jfs_open {
    my ( $file, $mode, $fi ) = @_;
    $file = fixup($file);
    warn sprintf("open \"$file\" mode=0%o", $mode);
    my $res = find($file);
    return $res if $res < 0;
    return -ENOENT unless $res;

    my $fd = IO::Handle->new;
    $fs{$fd} = { id => $res->[0]->id, buf => undef, dirty => 0,
		 mode => $mode };

    # Need this to prevent reads to use the disk file size.
    $fi->{direct_io} = 1;

    return ( 0, $fd );
}

sub jfs_create {
    my ( $file, $modes, $flags ) = @_;
    $file = fixup($file);
    warn sprintf("create \"$file\" mode=0%o", $flags);

    my $fd = IO::Handle->new;
    my @dirs = split( "/", $file );
    my $leaf = pop(@dirs);
    my $res = find( join( "/", @dirs ) );
    return $res if $res < 0;
    return -ENOSYS unless @$res;
    my $f = $res->[0];
    my $n = $f->create_note( $leaf, "" );
    $fs{$fd} = { id => $n->id, parent => $f, mode => $flags,
		 title => $leaf, buf => undef, dirty => 0 };

    return ( 0, $fd );
}

sub jfs_flush {
    my ( $file, $handle ) = @_;
    $file = fixup($file);
    unless ( defined($handle) ) {
	warn("flush: \"$file\" not open");
	return -ENOSYS;
    }
    if ( $fs{$handle}->{dirty} ) {
	if ( defined $fs{$handle}->{id} ) {
	    my $n = find($file)->[0];
	    $n->{body} = ${$fs{$handle}->{buf}};
	    $n->update;
	}
	else {
	    $fs{$handle}->{parent}->create_note( $fs{$handle}->{title},
						 ${$fs{$handle}->{buf}} )
	}
    }
    return 0;
}

sub jfs_release {
    my ( $file, undef, $handle ) = @_;
    unless ( defined($handle) ) {
	warn("release: \"$file\" not open");
	return -ENOSYS;
    }
    undef $fs{$handle};
    undef( $_[2] );
    return 0;
}

#### Read/write callbacks.

sub jfs_read {
    my ( $file, $bufsize, $off, $handle ) = @_;
    return -ENOSYS unless $handle;
    $file = fixup($file);
    printf STDERR ("read: %d at %d from \"%s\"\n",
		   $bufsize, $off, $file );

    unless ( $fs{$handle}->{buf} ) {
	my $res = $root->api->query("get", "/notes/".$fs{$handle}->{id}."?fields=body");
	${$fs{$handle}->{buf}} = $res->{body};
    }

    if ( $off >= 0 && $off <= length(${$fs{$handle}->{buf}}) ) {
	my $t = substr( ${$fs{$handle}->{buf}}, $off, $bufsize );
	warn sprintf("read: return %d bytes for \"$file\"", length($t));
	return $t;
    }
    return -ENOSYS;
}

sub jfs_write {
    my ( $file, $buf, $off, $handle ) = @_;
    unless ( defined $handle ) {
	warn("write: Opening $file");
	return -ENOSYS;
    }
    printf STDERR ("%s: %d at %d from \"%s\"\n",
		   $fs{$handle}->{mode} & O_APPEND ? "append" : "write",
		   length($buf), $off, $file );

    if ( $fs{$handle}->{mode} & O_APPEND && !$fs{$handle}->{buf} ) {
	my $res = $root->api->query("get", "/notes/".$fs{$handle}->{id}."?fields=body");
	${$fs{$handle}->{buf}} = $res->{body};
    }

    if ( ! $fs{$handle}->{buf} ) {
	my $b = "";
	if ( $off == 0 ) {
	}
	else {
	    $b .= " " x $off;
	}
	$b .= $buf;
	$fs{$handle}->{buf} = \$b;
    }
    elsif ( $off == length(${$fs{$handle}->{buf}})
	    || $fs{$handle}->{mode} & O_APPEND ) {
	${$fs{$handle}->{buf}} .= $buf;
    }
    else {
	${$fs{$handle}->{buf}} .= " " x ( $off - length(${$fs{$handle}->{buf}}));
	substr( ${$fs{$handle}->{buf}}, $off, length($buf), $buf );
    }
    $fs{$handle}->{dirty} = 1;
    return length($buf);
}

sub jfs_truncate {
    my ( $file, $off ) = @_;
    $file = fixup($file);
}

#### Unlink/rename.

sub jfs_unlink {
    my ( $file ) = @_;
    $file = fixup($file);
    my $note = find($file);
    return $note if $note < 0;
    $note->[0]->delete;
    return 0;
}

sub jfs_rename {
    my ( $old, $new ) = @_;
    $old = fixup($old);
    $new = fixup($new);

    my ( $target, $newname ) = ( $1, $2 ) if $new =~ m;^(.*)/([^/]+)$;;
    my ( $source, $oldname ) = ( $1, $2 ) if $old =~ m;^(.*)/([^/]+)$;;

    if ( $target eq $source ) {	# rename
	my $note = find($old);
	return $note if $note < 0;
	$note = $note->[0];
	$note->title($newname);
	$note->update;
	return 0;
    }
    else {			# move
	my $note = find($old);
	return $note if $note < 0;
	my $dest = find($new);
	return -EINVAL if UNIVERSAL::isa($note, 'Joplin::Base');
	$target = $target ne '' ? find($target) : $root;
	return $target if $target < 0;
	$note = $note->[0];
	$note->parent_id( $target->[0]->id );
	$note->update;
	return 0;
    }
}

#### Create/remove folders.

sub jfs_mkdir {
    my ( $name, $perm ) = @_;
    $name = fixup($name);
    my ( $target, $newname ) = ( $root, $name );
    ( $target, $newname ) = ( $1, $2 ) if $name =~ m;^(.*)/([^/]+)$;;

    my $note = find($target);
    return $note if $note < 0;
    $note->[0]->create_folder($newname);
    return 0;
}

sub jfs_rmdir {
    my ( $name ) = @_;
    $name = fixup($name);
    my $folder = find($name);
    return $folder if $folder < 0;
    $folder->[0]->delete;
    return 0;
}

#### Tags.

sub jfs_readlink {
    my ( $name ) = @_;
    warn("readlink($name)");
    $name = fixup($name);
    my $note = find($name);
    return -ENOSYS;
}

#### Miscellaneous.

sub jfs_utime {
    my ( $file, $atime, $mtime ) = @_;
    $file = fixup($file);
    return utime( $atime, $mtime, $file ) ? 0 : -$!;
}

sub callbacks {
    my @callbacks = qw( getattr readlink getdir create
			mknod mkdir unlink rmdir symlink
			rename link chmod chown truncate
			utime open release flush read write statfs );
    my %callbacks;
    foreach ( @callbacks ) {
	if ( my $op = main::->can("jfs_$_") ) {
	    $callbacks{$_} = $op;
	}
	else {
	    my $op = $_;
	    $callbacks{$_} = sub {
		warn("NYI: $op");
		return -ENOSYS;
	    };
	}
    }

    %callbacks;
}

################ Subroutines ################

# http://perldoc.perl.org/perlipc.html#Complete-Dissociation-of-Child-from-Parent
sub daemonize {
    chdir("/") || die( "can't chdir to /: $!" );
    open( STDIN, '<', '/dev/null' ) || die( "can't read /dev/null: $!" );
    if ( $logfile ) {
        open( STDOUT, '>', $logfile ) || die( "can't open logfile: $!" );
    }
    else {
        open( STDOUT, '>', '/dev/null') || die( "can't write to /dev/null: $!" );
    }
    defined( my $pid = fork() ) || die( "can't fork: $!" );
    exit if $pid; # non-zero now means I am the parent

    (setsid() != -1) || die( "Can't start a new session: $!" );
    open( STDERR, '>&', \*STDOUT ) || die( "can't dup stdout: $!" );
    if ( $pidfile ) {
        open( my $fd, '>', $pidfile );
        print $fd ( $$, "\n" );
        close($fd);
    }
}

sub system_capabilities {

    eval {
	require threads;
	require threads::shared;
	$has_threads = 1;
    };
    if ( $has_threads ) {
	threads->import();
	threads::shared->import();
    }

    eval {
	require Filesys::Statvfs;
	$has_Filesys__Statvfs = 1;
    };
    if ( $has_Filesys__Statvfs ) {
	Filesys::Statvfs->import();
    }

    eval {
	require Lchown;
	$use_lchown = 1;
    };
    if ( $use_lchown ) {
	Lchown->import();
    }

    eval {
	require Unix::Mknod;
	$has_mknod = 1;
    };
    if ( $has_mknod ) {
	Unix::Mknod->import();
    }
}

################ Subroutines ################

sub find {
    my ( $path ) = @_;

    return [ $root ] if $path eq '';

    my @dirs = split( "/", $path );
    my $leaf = pop(@dirs);

    my $f = $root;
    $path = "";
    foreach my $d ( @dirs ) {
	my $res = $f->find_folders( qr/^\Q$d\E$/ );
	return -ENOENT unless @$res;
	warn("Multiple results for dir \"$path$d\"") if @$res > 1;
	$f = $res->[0];
	$path .= $d . "/";
    }

    # Leaf can be a folder or a note.

    my $res = $f->find_notes (qr/^\Q$leaf\E$/ );
    $res = $f->find_folders( qr/^\Q$leaf\E$/ ) unless @$res;
    warn("Multiple results for \"$path" . ($leaf//'') . "\"") if @$res > 1;

    return $res;
}

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally
    my $use_threads = 0;	# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    GetOptions( 'ident'		     => \$ident,
		'server=s'	     => \$server,
		'apikey=s'	     => \$apikey,
		'prefix=s'	     => \$prefix,
		'use-threads'	     => \$use_threads,
		'use-real-statfs'    => \$use_real_statfs,
		'pidfile=s'	     => \$pidfile,
		'logfile=s'	     => \$logfile,
		'daemon!'	     => \$daemon,
		'verbose+'	     => \$verbose,
		'quiet'		     => sub { $verbose = 0 },
		'trace'		     => \$trace,
		'help|?'	     => \$help,
		'man'		     => \$man,
		'debug'		     => \$debug)
      or $pod2usage->(2);

    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->(1) if $help;
	$pod2usage->(VERBOSE => 2) if $man;
    }
    $extraopts{threaded} = $use_threads && $has_threads;
    $extraopts{debug} = $debug;
    $pod2usage->(2) unless @ARGV == 1;
}

__END__

################ Documentation ################

=head1 NAME

loopback - FUSE loopback file system

=head1 SYNOPSIS

loopback [options] mountpoint

 Options:
   --server=XXX		Jopin server
   --apikey=XXX		Joplin server API key
   --prefix=XXX		file system prefix (default: /joplin )
   --use-threads        uses threads
   --use-real-statfs    use real stat command if possible
   --pidfile=XXX        creates a file containing PID
   --logfile=XXX        directs stdout/stderr to file (default /dev/null)
   --ident		shows identification
   --help		shows a brief help message and exits
   --man                shows full documentation and exits
   --verbose		provides more verbose information
   --quiet		runs as silently as possible

=head1 OPTIONS

=over 8

=item B<--use-threads>

Uses perl threads, if available.

=item B<--use-real-statfs>

Uses real stat() command if possible.

If not, fake values are delivered.

=item B<--pidfile=>I<XXX>

Creates a file containing the PID of the fuse process.

=item B<--logfile=>I<XXX>

Directs stdout/stderr to the file.

By default all output is discarded.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.
This option may be repeated to increase verbosity.

=item B<--quiet>

Suppresses all non-essential information.

=item I<basedir>

The base directory of the real file tree.

=item I<mountpoint>

FUSE mountpoint for the real file tree.

=back

=head1 DESCRIPTION

B<This program> will perform a FUSE mount of the base directory on the
given mount point. From then on, the file tree under the mount point
will behave just like the original file tree.

B<IMPORTANT> Run B<fusermount -u> I<mountpoint> to
unmount the file system. Do not kill the fuse process.

=cut

