use strict;
use warnings;

package Ex;
our $VERSION = '0.092801';


use base 'Exporter';

our @EXPORT_OK = qw(&foo);

sub foo { return 'FOO' }

1;
