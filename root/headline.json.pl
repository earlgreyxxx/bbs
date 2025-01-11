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
use JSON;
do 'init.pl';

&{sub
{
  my $logfile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $num = 0;
  my $ctime = time;
  my $count = 0;
  my $limit = defined($FORM{'n'}) && int($FORM{'n'}) > 0 ? int $FORM{'n'} : $HEADLINE_LIMIT;
  my $filterHeadline = sub
    {
      my ($isPublic,$isShowHeadline) = (split /\//,(split /$split/,shift)[$L_ATTR])[$A_ARTICLE_PUBLIC,$A_SHOW_HEADLINE];

      return 0 unless($isPublic && $isShowHeadline);
      return ++$count < $limit ? 1 : -1;
    };
  &getLogEx($logfile,$L_KEY,$filterHeadline) || &cgiOut($ERROR_OPEN);

  shift @LOG;

  my $json =
    {
      'dir' => $DIR,
      'cgi' => $CGI_USER
    };
    
  my $rows = [];

  #ここに表示用のコードを書く
  foreach(@LOG)
    {
      if(exists $LOG{$_})
        {
          my $r = &parse($LOG{$_});

          my $items = $r->{items};
          my $direct = $r->{direct};
          my $notify = $r->{notify};
          my $period = $r->{notify_to};

          my @k = split(/-/,@{$r->{items}});
          my $date = stdio::getTime("%yyyy.%mm.%dd",32400,$k[$K_TIME]);

          my %row = ('date'   => $items->[$L_DATE],
                     'notify' => '',
                     'direct' => $direct ? stdio::urldecode_($direct) : undef,
                     'key'    => $items->[$L_KEY],
                     'title'  => $items->[$L_TITLE]);

          #####################################################
          #通知アイコンの表示  modified 2005/8/2 K.Nakagawa
          #####################################################
          if(($period && $period > $ctime && $notify) || (!$period && $notify))
            {
              $row{notify} = $NOTIFICATION_DISP[$notify];
            }
          #####################################################
          push @$rows,{%row};
        }
    }
  $json->{'rows'} = $rows;

  my $json_str = JSON->new->encode($json);

  my $callback =  $FORM{'callback'} ? $FORM{'callback'} : 0;
  #HTTPヘッダー
  &html_header([sprintf('Content-type:%s; charset=UTF-8',$FORM{'callback'} ? 'text/javascript' : 'application/json')]);

  #JSON/JSONP 出力
  print $callback ? sprintf('%s(%s);',$callback,$json_str) : $json_str;

}}(@ARGV);

1;