#!/usr/bin/perl

use Test::More tests => 13;
our $pkg;

use IO::File;
use File::Spec;

BEGIN { 
	$pkg = 'Sub::Import';
	# no. 1
	use_ok($pkg);
}

use strict;
eval q(use warnings) or local $^W = 1;

# no. 2
my $imp = $pkg->new();
isa_ok($imp, $pkg);

my $testfile = File::Spec->catfile('t','somesubs.pl');
# no. 3
my @subs = $imp->match_file($testfile);
ok(@subs > 0, 'got subs from file');

# no. 4
@subs = $imp->match_string(join '', IO::File->new($testfile)->getlines);
ok(@subs > 0, 'got subs from string');

{
	package TEST1;
	# no. 5
	eval { $imp->import(@subs) };
	Test::More::ok(!$@, 'imported subs ok');
	
	# no. 6
	Test::More::ok(defined &DoStuff, 'subs imported correctly');
}

{
	package TEST2;
	# no. 7
	my $imp = $pkg->new( { include => qr/^[a-z][\w_]+/ } );
	Test::More::isa_ok($imp, $pkg);

	# no. 8
	@subs = $imp->match_file($testfile);
	Test::More::ok(@subs == 1, 'matched only one sub');

	$imp->import(@subs);
	# no. 9
	Test::More::ok( (defined &munge_args and not defined &_secret),
	                'inclusion test');
}

{
	package TEST3;
	# no. 10
	my $imp = $pkg->new( { exclude => '^[A-Za-z]' } );
	Test::More::isa_ok($imp, $pkg);

	# local $Sub::Import::debug = 1;
	# no. 11
	@subs = $imp->match_file($testfile);
	Test::More::ok(@subs == 1, 'matched only one sub');

	$imp->import(@subs);
	# no. 12
	Test::More::ok( (defined &_secret and not defined &munge_args),
	                'exclusion test');
}

{
	# no. 13
	local $@;
	# this should throw an error
	eval { $pkg->import( q/nonexistant_file/ ) };
	ok($@, 'dies on bad files');
}
