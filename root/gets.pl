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
use JSON;
use List::Util qw/shuffle/;

our ($DIR_DATA,$DIR,$FDIR,$LOG_NAME,$HEADLINE_LIMIT,$DEFAULT_GET_KEYS);
our ($HTML_TITLE,$URL_CONTENT,$VERSION,$PAGE_MAX);
our ($split,@NOTIFICATION_DISP,$CGI_USER);

initialize();

# key name - url param('g') convert table
my %KEYS = (
  'd' => 'date',
  'n' => 'notify',
  'p' => 'period',
  'l' => 'direct',
  't' => 'title',
  'b' => 'body',
  'h' => 'headline',
  'c' => 'category',
  'r' => 'registed',
  'u' => 'lastupdate',
  'i' => 'images',
  'a' => 'attached',
  'o' => 'options',
);
my %SORTS = (
  'rand' => sub {
    my ($ar,$len,$ha) = @_;
    (shuffle(@$ar))[0 .. --$len];
  },
  'head' => sub {
    my ($ar,$len,$ha) = @_;
    @$ar[0 .. $len];
  },
  'tail' => sub {
    my ($ar,$len,$ha) = @_;
    (reverse(@$ar))[0 .. --$len];
  }
);

my %FILTER = (
  'last' => sub {

  },

);

my $DEFAULT_GET = defined $DEFAULT_GET_KEYS ? $DEFAULT_GET_KEYS : 'dnlt';

sub main
{
  my $logfile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my ($hlog,$alog) = LOGS();
  my $hform = FORM();
  my $num = 0;
  my $ctime = time;
  my $limit = is_exists_and_not_empty('n',$hform) ? int $hform->{'n'} : $HEADLINE_LIMIT;
  my $fetch = is_exists_and_not_empty('g',$hform) ? $hform->{'g'} : $DEFAULT_GET;
  my %fetch = map { $_,1 } split //,$fetch;
  my $s = is_exists_and_not_empty('s',$hform) ? $hform->{'s'} : 'head';
  my $f = is_exists_and_not_empty('f',$hform) ? $hform->{'f'} : '';

  # get log file with public entries.
  if($s eq 'head')
    {
      getLogEx($logfile,0,\&can_open_public_and_headline) || cgiOut(text('can not open file'));
    }
  else
    {
      getLogEx($logfile,0,\&can_open_public) || cgiOut(text('can not open file'));
    }

  cgiOut(text('invalid parameter')) unless exists $SORTS{$s};
  my $sort = $SORTS{$s};
  shift @$alog;

  # my $page = (defined $hform->{'page'} && 0 + $hform->{'page'} > 0) ? 0 + $hform->{'page'} : 1;
  # my $start = ($page - 1) * $PAGE_MAX;
  # my $end = $start + $PAGE_MAX - 1;
  # my $lognum = scalar @$alog;

  # article sorting and triming...
  @$alog = &$sort($alog,$limit);

  my $json = {
    'dir' => $DIR,
    'cgi' => $CGI_USER
  };

  my ($attached_dir,$attached_vdir) = get_attached_info(1);
  my $rows = [];

  #ここに表示用のコードを書く
  foreach(@$alog)
    {
      next unless(defined $_);
      if(exists $hlog->{$_})
        {
          my $r = parse($hlog->{$_});

          my $direct = $r->{direct};
          my $notify = $r->{notify};
          my $period = $r->{notify_to};

          my $row = {};
          $row->{'key'} = $r->{key};
          $row->{$KEYS{d}} = $r->{date} if(is_exists_and_not_empty('d',\%fetch));
          if(is_exists_and_not_empty('n',\%fetch))
            {
              $row->{$KEYS{n}} = $NOTIFICATION_DISP[$notify] if(($period && $period > $ctime && $notify) || (!$period && $notify));
            }
          $row->{$KEYS{p}} = $r->{notify_to} if(is_exists_and_not_empty('d',\%fetch));
          if(is_exists_and_not_empty('l',\%fetch))
            {
              $row->{$KEYS{l}} = $direct ? stdio::urldecode_($direct) : undef;
            }
          $row->{$KEYS{t}} = $r->{title} if(is_exists_and_not_empty('t',\%fetch));
          $row->{$KEYS{b}} = $r->{body} if(is_exists_and_not_empty('b',\%fetch));
          $row->{$KEYS{h}} = $r->{headline} if(is_exists_and_not_empty('h',\%fetch));
          $row->{$KEYS{c}} = $r->{category} if(is_exists_and_not_empty('c',\%fetch));
          $row->{$KEYS{r}} = $r->{registed} if(is_exists_and_not_empty('r',\%fetch));
          $row->{$KEYS{u}} = $r->{lastupdate} if(is_exists_and_not_empty('u',\%fetch));
          if(is_exists_and_not_empty('i',\%fetch))
            {
              my $oim = [];
              my $sim = [];
              foreach(@{$r->{images}})
                {
                  if($_)
                    {
                      push @$oim,$attached_vdir.'/'.$_;
                      push @$sim,$attached_vdir.(-e "$attached_dir/s/$_" ? '/s/' : '/').$_;
                    }
                }
              $row->{$KEYS{i}} = $oim;
              $row->{$KEYS{i}.'-s'} = $sim;
            }
          $row->{$KEYS{a}} = { order => $r->{attached_ords}, files => [ map { $attached_vdir . '/' . $_ } @{$r->{attached}} ] } if(is_exists_and_not_empty('a',\%fetch));
          $row->{$KEYS{o}} = $r->{options} if(is_exists_and_not_empty('o',\%fetch));

          push @$rows,$row;
        }
    }
  $json->{'rows'} = $rows;

  my $json_str = JSON->new->encode($json);

  my $callback =  $hform->{'callback'} ? $hform->{'callback'} : 0;
  #HTTPヘッダー
  http_header([sprintf('Content-type:%s; charset=UTF-8',$hform->{'callback'} ? 'text/javascript' : 'application/json')]);

  #JSON/JSONP 出力
  print $callback ? sprintf('%s(%s);',$callback,$json_str) : $json_str;
}

main();

1;
