#!/usr/bin/perl
###########################################################
=pod

=head1 Data attr cleaner

 アップロードできる画像数のログを増やします。
 先に property.pl に $NUM_OF_IMAGES を設定してください。

 一度増やしたら減らすことはできません。

=cut

##########################################################
use strict;
use warnings;

use utf8;
use open qw/:utf8 :std/;

#for windows console ('Windows.pm' file must be in @INC)
#use Windows;

use lib qw(../site-lib ../root ../root/inc);

$ENV{SCRIPT_NAME} = '/aaa/file.cgi';
$ENV{REQUEST_URI} = '/aaa/file.cgi';

require '../site-lib/stdio.pl';
require '../global.cgi';
require '../root/inc/corex.pl';

#Startup code
&{sub
{
  my $datadir = shift || '.';
  print 'please input valid directory name to change: ';
  my $dirname = STDIN->getline();
  chomp $dirname;
  my $dirpath = "$datadir/$dirname";

  -d $dirpath || die "not directory or not exists\n";
  print 'Do you want to set num of images? : ';
  my $num = STDIN->getline();
  chomp $num;
  die "please input over zero" if(0 >= int $num);

  increment($dirpath,$num);
      
}}(@ARGV);

sub increment
{
  my ($dirpath,$num) = @_;
  my $logpath = "$dirpath/log.dat.cgi";
  return 0 unless(-e $logpath);

  require "$dirpath/property.pl";

  our $NUM_OF_IMAGES;
  $num -= $NUM_OF_IMAGES;
  return 0 if(0 >= $num);

  my ($hlog,$alog) = &LOGS;

  getLogEx($logpath) || die "can not open $logpath\n";

  foreach(@{$alog}[1 .. $#$alog])
  {
    my $r = parse($hlog->{$_});
    my $attrib = $r->{attrib};
    my @images = @{$r->{images}};
    my @files = ();
    push @files,@images,('') x $num;
    foreach(@{$r->{attached_ords}})
    {
      push @files,$_,$r->{attached}{$_};
    }
    $r->{files} = \@files;
    $LOG{$_} = create_record($r);
  }

  my $newlogpath = $logpath . '.new';
  updateLog($newlogpath,'./temp.$$');
}

__END__
