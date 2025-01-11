#!/usr/bin/perl
###########################################################
=pod

=head1 Data converter
  convert data format from 'Log::Split' to 'Log::Dumper'

=cut

##########################################################
use strict;
use warnings;


use Data::Dumper;

use lib qw(../site-lib ../root ../root/inc .);
my $cd = $^O =~ m/mswin/i ? getcwd() : `pwd`;

chomp $cd;
$ENV{HTTP_HOST} = 'blue.system.ddk' unless $ENV{HTTP_HOST};
$ENV{REQUEST_URI} = "/cgi/bbs/admin";
$ENV{SCRIPT_NAME} = "/cgi/bbs/index.cgi";

require '../site-lib/stdio.pl';
require '../global.cgi';
require '../root/inc/corex.pl';

use IO::Dir;

our ($split,$split2,$NUM_OF_IMAGES);
our ($L_KEY,$L_TITLE,$L_DATE,$L_BODY,$L_ATTR,$L_FILE,$L_DELETE,$L_OPTION_START);

# no need import
require Log::Split;
require Log::Dumper;

#Startup code
&{sub
{
  my $datadir = shift || die "require data dir.\n";
  die "$datadir not found!\n" unless -d $datadir;
  require "$datadir/property.pl";

  foreach('Split','Dumper')
  {
    eval <<__CODE__;
    Log::${_}::init(\\\&toLOG,\$split,\$split2,\$NUM_OF_IMAGES);
    Log::${_}::inject(\$L_KEY,\$L_TITLE,\$L_DATE,\$L_BODY,\$L_ATTR,\$L_FILE,\$L_DELETE,\$L_OPTION_START);
__CODE__

    $@ && die "$@\n";
  }

  split_to_dumper("$datadir/log.dat.cgi");
}}(@ARGV);


sub split_to_dumper
{
  return unless(-e (my $logpath = shift));
  Log::Split::getLogEx($logpath) || return;
  my ($hlog,$alog) = LOGS();

  my $head = shift @$alog;
  $hlog->{$_} = Log::Dumper::create_record(Log::Split::parse($hlog->{$_})) foreach(@$alog);
  unshift @$alog,$head;

  storeLog(\&Log::Dumper::writeLine,$logpath,'./temp.$$');
}
sub dumper_to_split
{
  return unless(-e (my $logpath = shift));
  Log::Dumper::getLogEx($logpath) || return;
  my ($hlog,$alog) = LOGS();

  my $head = shift @$alog;
  $hlog->{$_} = Log::Split::create_record(Log::Split::parse($hlog->{$_})) foreach(@$alog);
  unshift @$alog,$head;

  storeLog(\&Log::Split::writeLine,$logpath,'./temp.$$');
}
sub storeLog
{
  our ($DIR_TEMPORARY);
  my ($writer,$logfile,$tempfile) = @_;
  return unless(ref $writer eq 'CODE');
  $tempfile = "$DIR_TEMPORARY/temp.$$" unless $tempfile;
  my ($hlog,$alog) = LOGS();

  my $fout = IO::File->new(">$tempfile") || die "can not open file\n";
  my $head = shift @$alog;
  $fout->print($hlog->{$head},"\n");
  foreach(@$alog)
    {
      $writer->($fout,$hlog,$_) if(exists $hlog->{$_});
    }
  $fout->close && move($tempfile,$logfile);
}
__END__
