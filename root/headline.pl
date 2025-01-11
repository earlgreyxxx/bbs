#!/usr/bin/perl
##############################################################################
# 
#  CGI Script  require Perl 5.003 or heigher.
#
#  Written by K.Nakagawa, except 'jcode','stdio' and 'date' packages
#
#   This script uses 'jcode.pl' and 'stdio.pl' and 'date.pl'.
#   Very thanks to their writer!!!
##############################################################################
use strict;
use warnings;

our ($DIR_DATA,$DIR,$FDIR,$LOG_NAME,$HEADLINE_LIMIT);
our ($HTML_TITLE,$URL_CONTENT,$VERSION);
our ($split,@NOTIFICATION_DISP,$CGI_USER);

initialize();
main();

sub main
{
  my $logfile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my ($hlog,$alog) = LOGS();
  my $hform = FORM();
  my $num = 0;
  my $ctime = time;
  my $limit = defined($hform->{'n'}) && int($hform->{'n'}) > 0 ? int $hform->{'n'} : $HEADLINE_LIMIT;

  my $oformat = defined $hform->{'type'} && $hform->{'type'} eq 'dt' ? '<span class="headline-date">%1$s</span>%2$s</span>' : '%2$s<span class="headline-date">(%1$s)</span>';
  getLogEx($logfile,0,make_headline_filter($limit)) || cgiOut(text('can not open file'));

  shift @$alog;

  http_header();
  print <<__HEADER__;
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>$HTML_TITLE - HeadLine - </title>
    <link rel="stylesheet" type="text/css" href="$URL_CONTENT/style.css?v=$VERSION" />
  </head>
  <body class="headline $DIR">
    <ul class="lines">
__HEADER__
  
  #ここに表示用のコードを書く
  foreach(@$alog)
    {
      if(exists $hlog->{$_})
        {
          my $r = &parse($hlog->{$_});

          my $direct = $r->{direct};
          my $notify = $r->{notify};
          my $period = $r->{notify_to};

          print qq(<li>);
          print ((($period && $period > $ctime && $notify) || (!$period && $notify)) ? $NOTIFICATION_DISP[$notify] : '');

          my $url = $direct ? stdio::urldecode_($direct) : qq(${CGI_USER}?dir=$DIR&article=$r->{key});
          my $target = '_parent';
          $target = '_blank' if($direct);
          printf($oformat,
                 $r->{date},
                 qq(<a class="headline-title" href="$url" target="$target">$r->{title}</a>));

          print qq(</li>\n);
        }
    }

  print <<__FOOTER__;
    </ul>
  </body>
</html>
__FOOTER__

}

1;
