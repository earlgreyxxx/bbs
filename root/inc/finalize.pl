#!/usr/bin/perl
##############################################################################
#
#  CGI Script  require Perl 5.008 or heigher.
#
#  Written by K.Nakagawa, except 'jcode','stdio' and 'date' packages
#
#   This script uses 'jcode.pl' and 'stdio.pl' and 'date.pl'.
#   Very thanks to their writer!!!
##############################################################################
unlink foreach(@stdio::file);

do {
  my @ctime = localtime; 
  my ($h,$d) = (localtime)[2,3];
  my $flag = "$DIR_TEMPORARY/.garbage";
  if($h == 12 && $d == 1)
  { 
    if(-e $flag)
    {
      Session::clean();
      rmdir($flag);
      print STDERR 'clear session files';
    } 
  }
  elsif(!-e $flag)
  {
    mkdir $flag;
  }

  1;
}
