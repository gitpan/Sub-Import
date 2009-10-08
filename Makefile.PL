
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Sub-Import',
  NAME      => 'Sub::Import',
  AUTHOR    => 'Ricardo\ Signes\ \<rjbs\@cpan\.org\>',
  ABSTRACT  => 'import\ routines\ from\ most\ anything\ using\ Sub\:\:Exporter',
  VERSION   => '0.092801',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Params::Util" => '0',
    "Sub::Exporter" => '0.900',
    "B" => '0',
    "Exporter" => '0',
    "Carp" => '0',
  },
  test => {TESTS => 't/*.t'}
);

