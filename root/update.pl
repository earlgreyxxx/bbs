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
use strict;
use warnings;
use List::Util qw/first/;

our ($DIR,$FDIR,$DIR_DATA,$LOG_NAME,$PAGE_MAX,$HTML_TITLE);
our ($L_KEY,$L_ATTR,$split);

initialize();
session_start($DIR);
main();
session_end();

sub main
{
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my ($hlog,$alog) = LOGS();
  my $hform = FORM();

  do 'article.pl';
  return if($@);

  #ここから出力
  if(exists $hform->{article})
    {
      my $headers;
      my $filter = sub {
        my ($key,$public) = @{parse(shift,1)}{'key','public'};
        -1 * ($key eq $hform->{article} && $public);
      };
      getLogEx($datafile,$L_KEY,$filter) || cgiOut(text('can not open file'));
      my $rheaders = getLogColumns(undef,undef,1);

      $headers = ['Status: 404 Not Found','Content-type: text/html'] if(!@$alog);

      http_header($headers);
      html_start($HTML_TITLE);
      table_article($hform->{article},$rheaders) if(@$alog);
      html_show_all();
      html_end();
    }
  else
    {
      my $page = (defined $hform->{'page'} && 0 + $hform->{'page'} > 0) ? 0 + $hform->{'page'} : 1;

      getLogEx($datafile, $L_KEY, $hform->{'cat'} ? \&category_can_open_public_not_direct  : \&can_open_public_not_direct) || cgiOut(text('can not open file'));
      my $rheaders = getLogColumns(undef,undef,1);

      my $start = ($page - 1) * $PAGE_MAX;
      my $end = $start + $PAGE_MAX - 1;

      #出力
      http_header();
      html_start($HTML_TITLE);

      for($start .. $end)
        {
          my $key = $alog->[$_];
          if($key && exists $hlog->{$key})
            {
              my @items = split(/$split/,$hlog->{$key});
              my @attrib = split(/\//,$items[$L_ATTR]);

              table_article($key,$rheaders);
            }
        }
      navigator($page,scalar(@$alog));
      html_end();
    }
}

1;
