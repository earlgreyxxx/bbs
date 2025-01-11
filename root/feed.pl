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

our ($DIR_DATA,$DIR,$FDIR,$LOG_NAME,$HEADLINE_LIMIT);
our ($HTML_TITLE,$URL_CONTENT,$VERSION);
our ($split,@NOTIFICATION_DISP,$CGI_USER,$CGI_FEED);
our ($FEED_AUTHOR,$FEED_DESCRIPTION);

initialize();
main();

sub main
{
  my $logfile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my ($hlog,$alog) = LOGS();
  my $hform = FORM();
  my $num = 0;

  getLogEx($logfile,0,make_headline_filter($HEADLINE_LIMIT)) || cgiOut(text('can not open file'));

  shift @$alog;

  my $url = "${CGI_FEED}?dir=$DIR";
  my $old_locale = setlocale(LC_ALL);
  setlocale( LC_ALL, "C" );
  my $lastupdate = pl_strftime('%a, %d %b %Y %H:%M:%S GMT',gmtime);
  setlocale( LC_ALL,$old_locale);

  print qq(Content-type: application/rss+xml\n\n);
  print <<__XML__;
<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"
	xmlns:content="http://purl.org/rss/1.0/modules/content/"
	xmlns:wfw="http://wellformedweb.org/CommentAPI/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:atom="http://www.w3.org/2005/Atom"
	xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
	xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
	>
<channel>
	<title>$HTML_TITLE</title>
	<atom:link href="$url" rel="self" type="application/rss+xml" />
	<link>${CGI_USER}?dir=$DIR</link>
	<description>$FEED_DESCRIPTION</description>
	<lastBuildDate>$lastupdate</lastBuildDate>
	<language>ja</language>
	<sy:updatePeriod>daily</sy:updatePeriod>
	<sy:updateFrequency>1</sy:updateFrequency>
	<generator>Update BBS</generator>
__XML__

  #ここに表示用のコードを書く
  foreach(@$alog)
    {
      if($hlog->{$_})
        {
          my @t = split(/$split/,$LOG{$_});
          my @a = split(/\//,$t[$L_ATTR]);
          my $notify = 0 + $a[$A_ARTICLE_NOTIFY];
          my $notify_to = 0 + $a[$A_ARTICLE_PERIOD];

          my @k = split(/-/,$t[$L_KEY]);
          my $pubDate = &getPubDate(int $k[$K_TIME]);
          my $content_encoded = $t[$L_BODY];
          my $description = $t[$L_BODY];
          $description =~ s/<.+?>//g;
          $description = mb_substr($description,0,70);

          print qq(<item>\n);
          print qq(<title>$t[$L_TITLE] ～ $t[$L_DATE] ～</title>\n);
          print qq(<link>${CGI_USER}?dir=$DIR&amp;article=$t[$L_KEY]</link>\n);
          print qq(<pubDate>$pubDate</pubDate>\n);
          print qq(<dc:creator><![CDATA[ $FEED_AUTHOR  ]]></dc:creator>\n);

          print qq(<guid isPermaLink="false">${CGI_USER}?dir=$DIR&amp;article=$t[$L_KEY]</guid>\n);
          print qq(<description><![CDATA[ $description  ]]></description>\n);
          print qq(<content:encoded><![CDATA[ $content_encoded  ]]></content:encoded>\n);
          print qq(</item>\n);
        }
    }

  print <<__XML__;
</channel>
</rss>
__XML__
}

sub mb_substr
{
  use Encode;
  my ($str,$offset,$len,$replace) = @_;
  $str = Encode::decode_utf8($str);
  $str = substr($str,$offset,$len,$replace);

  Encode::encode_utf8($str);
}

sub getPubDate
{
  my $time = shift;
  my($second, $minute, $hour, $mday, $mon, $year, $wday) = gmtime($time);
  my @month_string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
  my @week_string = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
  my $month = $month_string[$mon];
  my $week = $week_string[$wday];
  $year += 1900;
  $mday = sprintf("%02d", $mday);
  $hour = sprintf("%02d", $hour);
  $minute = sprintf("%02d", $minute);
  $second = sprintf("%02d", $second);

  return "${week}, ${mday} ${month} ${year} ${hour}:${minute}:${second} +0900";
}
1;
