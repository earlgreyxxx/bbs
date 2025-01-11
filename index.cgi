#!/usr/bin/perl
=com

 *notice
  can not support FAST-CGI and mod_perl because the global variables are scattered many.
  no using 'strict' because only compatiblity with old versions.

  ALL WRITTEN BY K.NAKAGAWA.

=cut
use strict;
use warnings;

use lib qw(./site-lib ./root ./root/inc .);
require 'stdio.pl';
require 'corex.pl';
require 'global.cgi';

our ($CGINAME,$CGI_ADMIN);

# invoke main script.

my $target = "./root/${CGINAME}.pl";
if(-e $target)
{
  require $target;
  print STDERR $@ if $@;

  print STDERR $@ unless do 'finalize.pl';
}
else
{
  redirect($CGI_ADMIN);
}

1;
