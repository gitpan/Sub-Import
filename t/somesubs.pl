#!/usr/bin/perl

$|++;
print "you're using a file made for the purposes of testing Sub::Import", $/,
			"so you probably shouldn't be here, good bye Dave";
sleep 1 and print ' .'  for 0 .. 2;
print $/;

exit 255;

sub munge_args {
	return map ucfirst, @_; # oooh lookey and unbalanced bracket --> }
}

sub DoStuff {
	print "I'm going to do stuff ... maybe\n";
	print map { chr rand $_ } (90) x 10 if rand(10) % 2;
}

sub _secret {
	# note the unbalanced bracket in quote below
	print "}:-> be vewwy vewwy quiet ...\n";
}
