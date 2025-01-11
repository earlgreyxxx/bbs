#!/usr/bin/perl
=pod

  Setup script (CGI/Perl 5.8 heigher)

   * create log.dat.cgi
   * chmod file/directory

=cut
use strict;
use warnings;
use utf8;
use open qw/:utf8 :std/;

#for windows console ('Windows.pm' file must be in @INC)
#use Windows;
use IO::Dir;
use IO::File;

#Startup code
&{sub
{
  my $no_chmod = shift;

  my @datadirs = mkdata('./data');
  my @attacheddirs = map { "$_/attached"; } @datadirs;
  my @logfiles = map { "$_/log.dat.cgi"; } @datadirs;

  chmod 0744,qw/admin.cgi feed.cgi fmanage.cgi headline.cgi headline.json.cgi index.cgi sign.cgi update.cgi/;

  return if($no_chmod);

  chmod 0777,qw/lock tempo/;
  chmod 0755,qw/admin.cgi feed.cgi fmanage.cgi headline.cgi headline.json.cgi index.cgi sign.cgi update.cgi/;
  chmod 0644,qw/global.cgi/;
  chmod 0777,@attacheddirs if(@attacheddirs > 0);
  chmod 0666,@logfiles if(@logfiles > 0);

  print "change file mode.\n";

}}(@ARGV);

sub mkdata
{
  my $dir = shift || 'data';
  return @dir unless(-d $dir);

  my @dir = map {
    next if(/^\.\.?$/ || !-d "./$dir/$_");

    my $logdir = "$dir/$_";
    my $logfile = "$logdir/log.dat.cgi";

    unless(-d "$logdir/attached")
      {
        mkdir "$logdir/attached";
        print "create directory... $logdir/attached\n";
      }

    IO::File->new($logfile,'>:utf8')->print('キー<>タイトル<>日付<>本文<>属性<>ファイル<>削除キー') unless(-e $logfile);
    $logdir;
  } IO::Dir->new($dir)->read;

  return @dir;
}

__END__

