#!/usr/bin/perl

package Sub::Import;

$VERSION = '0.5';

{
  use strict;
  eval q(use warnings) or local $^W = 1;

  use Carp;
  use IO::File;
  use Data::Dumper;
  use Regexp::Common;
  use UNIVERSAL qw( isa );

  sub new {
    my $class = shift;
    bless @_ ? shift : {}, $class;
  }

  sub _DEBUG {
    return unless defined $Sub::Import::debug and $Sub::Import::debug;
    # hey that looks familiar ...
    print STDERR @_, ' in ', [caller]->[1], ' at ', [caller]->[2], $/;
  }

  sub import {
    my $p = shift;

    my @subs;
    if(ref $p and isa($p, __PACKAGE__)) {
      @subs = exists $p->{files} ? @{ $p->{files} } : @_;
    } elsif(ref $_[0] eq 'HASH') {
      my $imp = bless shift, __PACKAGE__;
      @subs = map { $imp->match_file($_) } @{ $imp->{files} };
    } else {
      @subs = map { match_file($_) } @_;
    }

    _DEBUG "importing: [@subs]\n";

    {
      local $@;
      my $caller_pkg = caller;
      for (@subs) {
        eval qq(package $caller_pkg; $_);
        Carp::croak("subroutine import failed: $@")
          if $@;
      }
    }
  }

  sub match_file {
    my $self   = (ref $_[0] and $_[0]->isa(__PACKAGE__))
                  ? shift : __PACKAGE__->new(); 
    my $fl     = IO::File->new( $_[0] ) or Carp::croak("Bad file [$_[0]]: $!");

    return $self->match_string(join '', grep { !/^\s*#/ } <$fl>);
  }

  {
    ## the regexps below are take from the Sub::Lexical module
    ## with minor adjustments

    my $brackets_re     = $RE{balanced}{-parens => '{}'};
    my $paren_re        = $RE{balanced}{-parens => '()'};

    my $sub_name_re     = qr{[_a-zA-Z](?:[\w_]+)?};
    my $sub_proto_re    = qr{\([\$%\\@&\s]*\)};
    my $sub_attrib_re   = qr{(?:\s*:\s*$sub_name_re\s*(?:$paren_re)?)*}o;

    my $sub_extra_re    = qr{$sub_proto_re?$sub_attrib_re?}o;

                        ## sub foobar (proto) : attrib { "code" }
    my $sub_match_re    = qr{(                 # capture all
                               sub
                               \s+
                               $sub_name_re    # sub name
                               \s*
                               $sub_extra_re ? # optional prototype/attrib
                               \s*
                               $brackets_re    # match balanced brackets
                               \s*
                               ; ?             # optional literal ';'
                             )}xo;
    sub match_string {
      my $self   = (ref $_[0] and $_[0]->isa(__PACKAGE__))
                    ? shift : __PACKAGE__->new(); 

      my($string, @pieces) = _prepare_code( $_[0] );

      my @subs;
      push @subs, $1 while $string =~ m< \G .*? $sub_match_re >gsx;

      _DEBUG Dumper($self, \@subs);

      return grep {
        my $keep  = 1;
        my($name) = m< ^ sub \s+ ($sub_name_re) .*? { >x;
        
         $keep = $name =~ m[ $self->{include}  ]x
          if exists $self->{include};
        $keep = !($name =~ m[ $self->{exclude}  ]x)
          if exists $self->{exclude} and $keep;
        
        $_ = _restore_code($_, @pieces);
        $keep
      } @subs;
    }
  }

  {
    ## move this code munging into a separate module?
    use Text::Balanced qw( extract_quotelike extract_multiple );
    
    ## the following code has been bought to you by Damian Conway
    ## and the letters h, a, c and k and the number rand()

    my $ws  = qr/\s+/;
    my $id  = qr/\b(?!([ysm]|q[rqxw]?|tr)\b)\w+/;
    my $EOP = qr/\n\n|\Z/;
    my $CUT = qr/\n=cut.*$EOP/;
    my $pod_or_DATA = qr/
            ^=(?:head[1-4]|item) .*? $CUT
          | ^=pod .*? $CUT
          | ^=for .*? $EOP
          | ^=begin \s* (\S+) .*? \n=end \s* \1 .*? $EOP
          | ^__(DATA|END)__\n.*
            /smx;

    my $code_xtr = [
      $ws,
      { DONT_MATCH => $pod_or_DATA },
      $id,
      { DONT_MATCH => \&extract_quotelike }
    ];

    sub _prepare_code {
      local $_ = shift;

      my(@pieces, $instr);
      for ( extract_multiple($_, $code_xtr) ) {
        if(ref)        { push @pieces, $_; $instr = 0 }
        elsif($instr)  { $pieces[-1] .= $_ }
        else           { push @pieces, $_; $instr = 1 }
      }

      my $count = 0;
      $_ = join "", map {
             ref $_ ? $;.pack('N',$count++).$; : $_
           } @pieces;

      s<$RE{comment}{Perl}>()g;

      return $_, grep { ref $_ } @pieces;
    }
  }

  {
    my $extractor =   qr/\Q$;\E(\C{4})\Q$;\E/;
    sub _restore_code {
      my($code, @pieces) = @_;
      $code =~ s/$extractor/${$pieces[unpack('N',$1)]}/g;
      return $code;
    }
  }
}

q( I feel so use()d ... );

__END__

=head1 NAME

Sub::Import - safely import subroutines from any file

=head1 SYNOPSIS

  use Sub::Import qw( file_with_subs.pl );

  sub_from_file( @ARGV );

  my $imp = Sub::Import->new( exclude => qr/^_/ );
  my @public_subs = $imp->match_file( 'a_module.pm' );

=head1 DESCRIPTION

Ever wanted to C<require()> a file just for it's subroutines but had to end up
copying and pasting because the file executed code? If the answer to the
previous question was /^yes!?/i then this is the module for you! It will
cleanly extract subroutines from a given file and import them into the
current package.

=head2 USAGE

You can extract subroutines from files in the following ways

=over 4

=item use() a list

This will extract all the subroutines in the given files and import them into
the current package.

  use Sub::Import qw(list)

=item use() a hash ref

Provide a hash ref which has the key C<files> pointing to an array of files.
If there are any rules in the hash ref they will also be applied.

  use Sub::Import { files => [], %rules }

=item OO interface

Use the OO interface provided. Although remember that importing like this
won't be processed until runtime, unlike the C<use>.

  use Sub::Import;
  my $imp = Sub::Import->new( { files => [], %rules } );
  $imp->import();

  # or

  my $imp = Sub::Import->new();
  $imp->import( @files );

=back

=head2 METHODS

=over 4

=item new($options)

The class constructor method. It takes one parameter which is a hash ref
of options which can consist of the following

  {
    files   => [],        # files to be processed
    # NOTE - these are mentioned above as rules
    include => 'pattern', # include subs whose names match 'pattern'
    exclude => 'pattern', # reverse of include
  }

=item import([ $hashref | @files ])

Will import given subs with a touch of DWIM

  use Sub::Import qw( files );    # process files
  use Sub::Import { %options };   # process $options{files}

  my $imp1 = Sub::Import->new($options);
  $imp1->import();                # process $imp1->{files}
  my $imp2 = Sub::Import->new();
  $imp->import( @files );         # process @files

=item match_file($filename)

Returns a list of subroutines (as strings) extracted from C<$filename>

=item match_string($string)

Same as C<match_file()> but processes the given C<$string>

=back

=head1 EXAMPLE

Say you have some legacy code and would like to use but fear C<require()>ing
forsooth it breaketh your wonderful new program. If the subs aren't
dependent on anything else in the code then you can safely bring them into
your current program like so

  {
    package Legacy;
    use Sub::Import qw ( /usr/local/lib/perl4/LegacyCode.ph );
  }

  my $handle = Legacy::get_database(@args);

Now you have your old code nicely encapsulated in it's own package, hurrah!

=head1 BUGS

If you have an unbalanced ending bracket in a HERE doc within a sub the
extractor breaks and returns an incomplete subroutine e.g

  sub buggy {
    print <<"    TXT";
    devil face is bad }:->
    TXT
  }

The returned sub will end at the beginning of the emoticon.

=head1 TODO

=over 2

=item x

Try to import variables that the imported subroutines rely upon, and maybe
prove the Riemann Hypothesis while I'm at it.

=item x

Get C<_prepare_code()> to deal with HERE docs.

=back

=head1 THANKS

Thanks again to Damian Conway's marvellous Filter::Simple (used in
C<_prepare_code()> and C<_restore_code()>

=head1 AUTHOR

Dan Brook C<E<lt>broquaint@hotmail.comE<gt>>

=head1 COPYRIGHT

Copyright (c) 2002, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same terms
as Perl itself.

=cut
