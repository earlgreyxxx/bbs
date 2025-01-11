#!/usr/bin/perl
###########################################################
=pod

=head1 Data attr cleaner

 古いログの属性定義をクリアし、登録日付を追加します。

=cut

##########################################################
# use utf8;
# use open qw/:utf8 :std/;

use File::Copy;
use File::Basename;
#for windows console ('Windows.pm' file must be in @INC)
use Windows;

use lib qw(../site-lib ../root ../root/inc);

$ENV{SCRIPT_NAME} = '/aaa/file.cgi';
$ENV{REQUEST_URI} = '/aaa/file.cgi';

require '../site-lib/stdio.pl';
require '../global.cgi';
require '../root/inc/corex.pl';

use IO::Dir;

#Startup code
&{sub
{
  my $datadir = shift || '.';
  our $DIR;
  our $dir_attached;

  foreach(IO::Dir->new($datadir)->read)
    {
      next if(/^\.+$/ || !-d);
      $DIR = $_;
      $dir_attached = dirname(__FILE__) . "/../../../post/uploads/$DIR";

      &module_initialize;
      &correct("$datadir/$_/log.dat.cgi");
    }
      
}}(@ARGV);

sub fileMove
{
  our $dir_attached;
  my $filename = shift;
  my $path = $dir_attached;
  my $protectpath = sprintf('%s/%s',$dir_attached,$DIR_PROTECTED_NAME);
  mkdir $path unless(-d $path);

  my $cpath = sprintf('%s/%s',$path,$filename);
  my $newpath = sprintf('%s/%s',$protectpath,$filename)
  print "$cpath\n$newpath\n\n";
  # move($cpath,$newpath);
}

sub correct
{
  my $logpath = shift;
  return unless(-e $logpath);

  my ($hlog,$alog) = &LOGS;
  print 'processing ',$logpath,"\n";

  getLogEx($logpath) || return;

  my $head = shift @$alog;
  foreach(@$alog)
    {
      my $r = parse($hlog->{$_});
      my $attrib = $r->{attrib};
      my $image = $r->{image};
      my $public = $r->{public};
      my $attached = $r->{attached};
      my $attached_ords = $r->{attached_ords};

      $r->{direct} = $attrib->[15];
      $r->{lastupdate} = '';
      $r->{registdate} = (split /-/,$r->{key})[4];
      $r->{category} = '';

      if(!$public)
        {
          fileMove($image) if($image);
          if(@$attached_ords)
            {
              fileMove($_) foreach(@$attached_ords);
            }
        }

      $hlog->{$_} = create_record($r);
    }
  unshift @$alog,$head;
  my $newlogpath = $logpath . ".$$.new";

  &updateLog($newlogpath,'./temp.$$');
  &LOG_CLEAR;
}

__END__
