#! perl

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010000;

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

my $master = 'lib/Joplin/API.pm';
my $version = MM->parse_version($master);

my @bins = qw( );

WriteMakefile
(
 NAME		=> 'Joplin::API',
 ABSTRACT_FROM  => $master,
 VERSION	=> $version,
 AUTHOR	        => 'Johan Vromans <jvromans@squirrel.nl>',
 LICENSE	=> "perl",
 MIN_PERL_VERSION => 5.010000,
 INSTALLDIRS	=> 'site',
 EXE_FILES	=> [ map { "script/$_" } @bins ],
 PL_FILES	=> {
		    'script/pp.PL' => [ map { "script/$_" } @bins ]
		   },

 PREREQ_PM      => {
		    'LWP::UserAgent' => 6.13,
		    'JSON'	     => 2.94,
		   },

 CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => 6.5503,
 },

# BUILD_REQUIRES => {
# },

 TEST_REQUIRES  => {
		    'Test::More'  => 0,
		   },

 META_MERGE => {
     resources => {
	 license    => "http://dev.perl.org/licenses/",
	 repository => "https://github.com/sciurius/perl-Joplin-API",
	 bugtracker => "https://github.com/sciurius/perl-Joplin-API/issues",
     },
     provides => {
	 "Joplin::API"
		  => { file => "lib/Joplin/API.pm",
		       version => $version },
     },
     no_index => {
         file => [
	 ],
         directory => [
	 ],
     },
 },

);

# Note about the no_index: CPAN and MetaCPAN have differing opinions
# on how no_index must be interpreted, in particular in combination
# with provides.

