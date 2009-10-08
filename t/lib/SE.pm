use strict;
use warnings;

package SE;
our $VERSION = '0.092801';



use Sub::Exporter -setup => {
  exports => [ qw(foo) ],
};

sub foo { return 'FOO' }

1;
