#!/usr/bin/perl

use Test::More tests => 3;
use vars qw/$pkg/;

BEGIN { 
	$pkg = 'Sub::Import';
	# no. 1
	use_ok($pkg);
}

use strict;

# no. 2
ok($pkg->VERSION > 0,	'version number set');

# no. 3
my $imp = $pkg->new();
isa_ok($imp, $pkg);
