use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Sub::Import',
    'VERSION_FROM'	=> 'Import.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       'Regexp::Common'	=> 0.1,
       'Text::Balanced' => 1.83,
    }, # e.g., Module::Name => 1.1

#    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
#      (ABSTRACT_FROM => 'Import.pm', # retrieve abstract from module
#       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),

);
