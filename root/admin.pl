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
no warnings 'uninitialized';
use CGI::Carp qw/fatalsToBrowser/;
use File::Copy;
use List::Util qw/first/;
use URI::Escape;
use Time::Local 'timelocal';
use Data::Dumper;
use Digest::SHA qw/sha1_hex/;

our (%COOKIE,$DIR,$FDIR,$split,$split2,$DIR_DATA,$COOKIE_LIFETIME);
our (%CONVERT_TABLE,$CGI_SELF,$CGI_SIGNIN,$DATE_TITLE);
our ($DIR_PASSWORD,$LOG_NAME,$HTML_TITLE,$DELETE_KEY,$LOCK_NAME,$NUM_OF_IMAGES);
our (@CATEGORIES,%CATEGORIES);

require 'admin.inc.pl';

initialize(1);

#Sessionのリダイレクト処理をオーバーライドする。
{
  no warnings qw/once redefine/;
  my $hform = FORM();
  *Session::session_redirect = sub {
    my $done = '&done=' . uri_escape("$CGI_SELF?$ENV{QUERY_STRING}");
    my $dir = $hform->{'dir'} ? "dir=$hform->{dir}" :  '';
    print "Location: $CGI_SIGNIN?$dir$done\n\n";
    exit;
  };
}

session_start($DIR);
main();
session_end();

sub main
{
  no strict 'refs';
  my $hform = FORM();
  #Start authentication. require cookie.
  redirect(sprintf('%s?dir=%s&done=%s',
                   $CGI_SIGNIN,
                   $hform->{dir},
                   uri_escape("$CGI_SELF?$ENV{QUERY_STRING}"))) unless(validate_session($DIR_PASSWORD));

  cgiOut(text('can not open file')) unless(-e "$DIR_DATA/$FDIR/$LOG_NAME");

  # mode dispatch
  &{*{'on'.ucfirst(exists $hform->{mode} && $hform->{mode} ? $hform->{mode} : 'show')}{CODE}} ();
}

###################################################
# mode 指定なし
###################################################
sub onShow
{
  our ($PAGE_MAX);
  my $hform = FORM();
  my ($hlog,$alog) = LOGS();
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $page = (defined $hform->{'page'} && 0 + $hform->{'page'} > 0) ? 0 + $hform->{'page'} : 1;
  my $dp = $hform->{'dp'};
  my %DP = ();
  my $is_list = 0;

  session_value('page',$page);

  getLogEx($datafile) || cgiOut(text('can not open file'));
  my @headers = getLogColumns($hlog,$alog,1);

  my $start = ($page - 1) * $PAGE_MAX;
  my $end = $start + $PAGE_MAX - 1;
  my $lognum = scalar @$alog;

  stdio::getCookie(\%DP,"DP");
  my $ck = "dp=list";

  if($dp eq 'list')
    {
      stdio::setCookie(\$ck,'DP',$COOKIE_LIFETIME);
      $is_list = 1;
    }
  elsif($dp eq 'article')
    {
      stdio::setCookie(\$ck,'DP',-1);
      $is_list = 0;
    }
  elsif($DP{dp} eq 'list')
    {
      $is_list = 1;
    }

  #ここから出力
  http_header();
  html_admin_start($HTML_TITLE,
                   [\&html_head_show, !$DELETE_KEY ? \&html_admin_enumeration_script : undef],
                   'admin-list');

  # html_admin_menu();
  html_admin_comments();

  pager($page,$lognum,1);
  if($is_list)
    {
      my @templates = &get_admin_list_templates;
      print shift @templates;
      for($start .. $end)
        {
          table_admin_list($_,$alog->[$_]) if($hlog->{$alog->[$_]});
        }
      print shift @templates;
    }
  else
    {
      for($start .. $end)
        {
          table_admin_article($_,$alog->[$_],\@headers) if($hlog->{$alog->[$_]});
        }
    }
  pager($page,$lognum,1);

  html_dkey_script() if($DELETE_KEY);
  html_admin_end(\&html_foot_show);
}

###################################################
#
###################################################
sub onCancel
{
  my $token = FORMVALUE('ct');
  if($token)
    {
      delete_token($token);
    }
  else
    {
      my $cookie = {};
      stdio::getCookie($cookie,'tn');
      $token = $cookie->{token};
      close_token($token) if($token);
    }

  return onShow();
}

#######################################################################
# outline.cgi/headline.cgi での表示・非表示および保留設定の変更処理
#######################################################################
sub onDisplaycheck
{
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $is_modify = 0;
  my $hform = FORM();
  my $hlog = LOG();

  my $index = $hform->{'index'};
  my $public = 0 + $hform->{'public'};
  my $outline = 0 + $hform->{'outline'};
  my $headline = 0 + $hform->{'headline'};
  my $public_attrib = $public ? 0 : 1;

  cgiOut(text('there is no index')) unless($index);
  cgiOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  cgiOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));
  cgiOut(text('specified index value is unavailable'),$LOCK_NAME) unless($hlog->{$index});

  my $r = parse($hlog->{$index});
  my $public_old = $r->{public};
  @$r{'public','outline','headline'} = ($public_attrib,$outline,$headline);

  $hlog->{$index} = create_record($r);
  MoveFiles($r,$r->{public}) if($public_old != $r->{public});
  updateLog($datafile);

  stdio::unlock($LOCK_NAME);
  redirect(add_page("$CGI_SELF?dir=$DIR",'&')."#article-$index");
}

sub toggleProtected
{
  my $public = shift;
  my $index = FORMPARAM('index');
  my $hlog = LOG();
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";

  cgiOut(text('there is no index')) unless($index);
  cgiOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  cgiOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));
  cgiOut(text('specified index value is unavailable'),$LOCK_NAME) unless($hlog->{$index});

  my $r = parse($hlog->{$index});
  my $public_old = $r->{public};
  $r->{public} = $public;
  $hlog->{$index} = create_record($r);

  MoveFiles($r,$r->{public}) if($public_old != $r->{public});
  updateLog($datafile);

  stdio::unlock($LOCK_NAME);
  redirect(add_page("$CGI_SELF?dir=$DIR",'&')."#article-$index");
}

sub onProtected
{
  return toggleProtected(0);
}

sub onUnprotected
{
  return toggleProtected(1);
}

######################################################################
#記事修正
######################################################################
sub onModify
{
  our $DIR_TEMPORARY;
  my $hform = FORM();
  my $action = $hform->{'ac'};
  my $index = $hform->{'index'};

  cgiOut(text('there is no index')) if(!$index);

  if($action eq 'show')
    {
      onModify_Show();
    }
  elsif($action eq 'post')
    {
      processGarbage($DIR_TEMPORARY);
      onModify_Post();
    }
  else
    {
      redirect(add_page("$CGI_SELF?dir=$DIR",'&'));
    }
}

sub onModify_Show
{
  our ($L_KEY);
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $index = FORMVALUE('index');

  cgiOut(text('can not open file')) unless(getLogEx($datafile,$L_KEY,$L_KEY,$index));
  cgiOut(text('specified index value is unavailable')) unless(LOG()->{$index});

  http_header();
  html_admin_start($HTML_TITLE, [\&html_head_edit, \&html_form_process_script, \&html_manager_script]);
  html_header_title(text('Modify Article'));
  form_modify($index);
  html_admin_end();
}

sub onModify_Post
{
  our (%DC,$L_OPTION_START);
  my $hform = FORM();
  my $hlog = LOG();
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $index = $hform->{'index'};
  my $token = $hform->{'token'};

  cgiOut(text('invalid process')) unless(verify_token($token));
  cgiOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  cgiOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));
  cgiOut(text('specified index value is unavailable'),$LOCK_NAME) unless($hlog->{$index});

  #ここに修正処理
  my $r = parse($hlog->{$index});

  #削除キー認証スタート
  if($DELETE_KEY && !delete_auth($r->{dkey}))
    {
      stdio::unlock($LOCK_NAME);
      delete_failure();
    }
  #認証ここまで

  my $public = 0 + $hform->{'public'};
  my $pub_attrib = $public == 1 ? '0' : '1';
  my $notify = 0 + $hform->{'notification'};
  my $notify_period = do {
    my ($y,$m,$d) = exists $hform->{'notify_period'} && $hform->{'notify_period'} ? split(/[\/\-]/,$hform->{'notify_period'}) : (0,0,0);
    ($y && $m && $d) ? timelocal(59, 59, 23, $d, $m - 1, $y - 1900) : '';
  };
  my $outline = ($hform->{'outline'} == 1) ? 1 : 0;
  my $headline = ($hform->{'headline'} == 1) ? 1 : 0;
  my $directlink = $hform->{'direct'} ? $hform->{'direct'} : '';
  my $lastupdate = time;
  $directlink =~ tr/ //d if($directlink);
  $directlink = uri_escape($directlink);

  my @cats = split /$split/,$hform->{'category'};
  my $cats = 0;
  foreach(@cats)
    {
      $cats |= $CATEGORIES{$_}{flag} if(exists $CATEGORIES{$_});
    }

  my $reserve = do {
    my ($y,$m,$d) = exists $hform->{'reserve'} && $hform->{'reserve'} ? split(/[\/\-]/,$hform->{'reserve'}) : (0,0,0);
    ($y && $m && $d) ? timelocal(59, 59, 23, $d, $m - 1, $y - 1900) : '';
  };

  #ここからログ項目(タイトル/サブタイトル/本体/属性)
  $r->{title} = $hform->{'title'};
  $r->{date} = $hform->{'date'};

  $r->{body} = $hform->{'body'};
  $r->{body} =~ s/&([a-z]+);/$CONVERT_TABLE{$1}/ig;
  $r->{body} =~ s/<\/?script.*?>//g;
  $r->{body} =~ s/<\/?object.*?>//g;
  $r->{body} =~ s/[\r\n]//g;

  if($DELETE_KEY && length $hform->{dkey} > 0)
    {
      if($DELETE_KEY == 1)
        {
          $r->{dkey} = $hform->{'dkey'};
        }
      elsif($DELETE_KEY == 2)
        {
          $r->{dkey} = md5crypt($hform->{'dkey'});
        }
    }

  #ここから画像置換
  my ($attacheddir) = get_attached_info($r->{public});
  my $images = $r->{images};
  for(0 .. $NUM_OF_IMAGES - 1)
    {
      my $origimage = $images->[$_];
      if(($hform->{"delete-image_$_"} || ($_ == 0 && $hform->{'delete-image'})) && $origimage)
        {
          unlink "$attacheddir/$origimage","$attacheddir/s/$origimage";
          $images->[$_] = '';
        }

      if($hform->{"image_$_->name"} || ($_ == 0 && $hform->{'image->name'}))
        {
          my $keyname = (!$hform->{"image_$_->name"} && $_ == 0 && $hform->{'image->name'}) ? 'image' : "image_$_";
          my $imagename = saveFile($hform,$keyname,$attacheddir);

          createSmallImage($imagename,$attacheddir);
          unlink "$attacheddir/$origimage","$attacheddir/s/$origimage";
          $images->[$_] = $imagename;
        }
    }
  MoveFiles($r,$pub_attrib) if($pub_attrib != $r->{public});

  #ここからログ項目(オプション)
  my @headers = getLogColumns();
  my @optionHeaders = splice @headers,$L_OPTION_START;
  for(0 .. $#optionHeaders)
    {
      $r->{options}->[$_] = length $hform->{"option_$_"} ? $hform->{"option_$_"} : '';
    }

  # 属性上書き
  my @attrib = qw/direct lastupdate category reserve public notify notify_to outline headline/;
  @$r{@attrib} = ( $directlink,
                   time,
                   $cats,
                   $reserve,
                   $pub_attrib,
                   $notify,
                   $notify_period,
                   $outline,
                   $headline );

  #データ上書き
  $hlog->{$index} = create_record($r);
  updateLog($datafile);
  stdio::unlock($LOCK_NAME);

  #ここまで
  stdio::setCookie(\%DC,'DK',-1) if($DELETE_KEY);
  delete_token($token);
  redirect(add_page("$CGI_SELF?dir=$DIR",'&') . "#article-$index");
}

######################################################################
#順番入替
######################################################################
sub onOrder
{
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $hform = FORM();
  my ($hlog,$alog) = LOGS();

  my $index = $hform->{'index'};
  my $ord = int $hform->{'ord'};
  # up:11, down:22, top:110, bottom: 220

  cgiOut(text('there is no index')) unless($index);
  cgiOut(text('arguments are missing')) unless($ord);
  cgiOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  cgiOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));
  cgiOut(text('there is no index'),$LOCK_NAME) unless($hlog->{$index});

  my $modify = (first { $alog->[$_] eq $index } (1 .. $#$alog)) || 0;

  my ($h,$t);
  if($ord == 11 && $modify != 1)
    {
      $t = $alog->[$modify - 1];
      $alog->[$modify - 1] = $alog->[$modify];
      $alog->[$modify] = $t;
    }
  elsif($ord == 22 && $modify != $#$alog)
    {
      $t = $alog->[$modify + 1];
      $alog->[$modify + 1] = $alog->[$modify];
      $alog->[$modify] = $t;
    }
  elsif($ord == 110 && $modify != 1)
    {
      $t = $alog->[$modify];
      $h = $alog->[0];
      splice @$alog,$modify,1;

      $alog->[0] = $t;
      unshift @$alog,$h;
    }
  elsif($ord == 220 && $modify != $#$alog)
    {
      $t = $alog->[$modify];
      splice @$alog,$modify,1;
      push @$alog,$t;
    }

  updateLog($datafile);
  stdio::unlock($LOCK_NAME);
  redirect(add_page("$CGI_SELF?dir=$DIR",'&') . "#article-$index");
}

######################################################################
#クローン処理
######################################################################
sub onClone
{
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $hform = FORM();
  my ($hlog,$alog) = LOGS();

  my $index = $hform->{'index'};
  my $is_copyfile = $hform->{'copyfile'} ? 1 : 0;

  cgiOut(text('there is no index')) unless($index);
  cgiOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  cgiOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));
  cgiOut(text('specified index value is unavailable'),$LOCK_NAME) unless($hlog->{$index});

  my $r = parse($hlog->{$index});
  my $image = $r->{image};
  my $attached = $r->{attached};
  my $order = $r->{attached_ords};

  # copy images and attached files.
  if($is_copyfile)
    {
      CopyFiles($r);
    }
  else
    {
      $r->{attached} = {};
      $r->{attached_ords} = [];
      $r->{images} = [ ('') x $NUM_OF_IMAGES ];
    }

  $r->{key} = getLUID();
  $r->{public} = 0 if($r->{public});

  my $head = $alog->[0];
  $alog->[0] = $r->{key};
  unshift @$alog,$head;

  $hlog->{$r->{key}} = create_record($r);

  updateLog($datafile);
  stdio::unlock($LOCK_NAME);
  redirect("$CGI_SELF?dir=$DIR");
}

######################################################################
#記事削除
######################################################################
sub onRemove
{
  our $DIR_TEMPORARY;
  my $hform = FORM();
  my $action = $hform->{'ac'};
  my $index = $hform->{'index'};

  cgiOut(text('there is no index')) if(!$index);

  if($action eq 'show')
    {
      onRemove_Show($index);
    }
  elsif($action eq 'exec')
    {
      processGarbage($DIR_TEMPORARY);
      onRemove_Exec($index);
    }
  else
    {
      redirect(add_page("$CGI_SELF?dir=$DIR",'&'));
    }
}

sub onRemove_Show
{
  our $L_KEY;
  my $index = $_[0];
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my ($hlog,$alog) = LOGS();
  cgiOut(text('can not open file')) unless(getLogEx($datafile,$L_KEY,$L_KEY,$index));
  cgiOut(text('there is no index')) unless($hlog->{$index});

  unless(delete_auth($index))
    {
      delete_failure();
      cgiExit();
    }

  my @headers = split /$split/,$hlog->{shift @$alog};
  my $token = publish_token();

  http_header();
  html_admin_start($HTML_TITLE,undef,'remover');
  html_confirm($index,
               qq($CGI_SELF?mode=remove&ac=exec&dir=$DIR&index=$index),
               add_page("$CGI_SELF?mode=cancel&dir=$DIR",'&').qq(#article-$index),
               text('remove article, ok?'));
  table_admin_article(undef,$index,\@headers,1);
  html_admin_end();
}

sub onRemove_Exec
{
  my $index = $_[0];
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $hlog = LOG();
  my $cookie = {};
  stdio::getCookie($cookie,'tn');
  my $token = $cookie->{token};

  cgiOut(text('invalid process')) unless(verify_token($token));
  cgiOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  cgiOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));
  cgiOut(text('there is no index'),$LOCK_NAME) unless($hlog->{$index});

  my $r = parse($hlog->{$index});
  my $items = $r->{items};
  my $images = $r->{images};

  my ($attacheddir) = get_attached_info($r->{public});

  #削除キー認証スタート

  if($DELETE_KEY && !&delete_auth($index))
    {
      stdio::unlock($LOCK_NAME);
      delete_failure();
    }
  #認証ここまで

  my @remove = map {
    my $image = $images->[$_];
    "$attacheddir/$image","$attacheddir/s/$image" if($image);
  } 0 .. $NUM_OF_IMAGES - 1;

  push @remove,map { sprintf('%s/%s',$attacheddir,$_); } @{$r->{attached_ords}};
  delete $hlog->{$index};

  unlink(@remove) if(@remove);

  updateLog($datafile);
  stdio::unlock($LOCK_NAME);
  #ここまで

  if($DELETE_KEY)
    {
      my $dkey = session_value('dkey');
      delete $dkey->{$index} if($dkey);
    }

  close_token($token);
  redirect(add_page("$CGI_SELF?dir=$DIR",'&'));
}


######################################################################
#新規投稿処理
######################################################################
sub onPost
{
  our $DIR_TEMPORARY;
  my $hform = FORM();
  my $action = $hform->{'ac'};

  if($action eq 'post')
    {
      processGarbage($DIR_TEMPORARY);
      onPost_Post();
    }
  elsif($action eq 'show')
    {
      onPost_Show($hform->{'index'});
    }
  else
    {
      redirect(add_page("$CGI_SELF?dir=$DIR",'&'));
    }
}

sub onPost_Show
{
  my $index = shift || undef;
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";

  getLogHeader($datafile) || cgiOut(text('can not open file'));

  http_header();
  html_admin_start($HTML_TITLE, [\&html_head_edit, \&html_form_process_script]);
  html_header_title(text('Create Article'));
  form_post();
  html_script_article($index) if($index);
  html_admin_end();
}

sub onPost_Post
{
  our $L_OPTION_START;
  my $hform = FORM();
  my ($hlog,$alog) = LOGS();
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";

  my $token = $hform->{'token'};

  my @new;
  my %attached;
  my @attached_ord;
  my $at = 0 + $hform->{'at'};
  my $locate = 0 + $hform->{'locate'};
  my $dkey;

  my $outline = ($hform->{'outline'} == 1) ? 1 : 0;
  my $headline = ($hform->{'headline'} == 1) ? 1 : 0;

  my %cookie_default = ();

  if($DELETE_KEY)
    {
      if(length($hform->{'dkey'}) == 0)
        {
          cgiOut(text('require delete key'));
        }
      else
        {
          if($DELETE_KEY == 1)
            {
              $dkey = $hform->{'dkey'};
            }
          elsif($DELETE_KEY == 2)
            {
              $dkey = md5crypt($hform->{'dkey'});
            }
        }
    }

  cgiOut(text('invalid process')) unless(verify_token($token));
  cgiOut(text('process is busy state')) if(!stdio::lock($LOCK_NAME));
  cgiOut(text('can not open file'),$LOCK_NAME) unless(getLogEx($datafile));

  my @headers = split(/$split/,$hlog->{$alog->[0]});
  my @options = splice(@headers,$L_OPTION_START);

  my $public = 0 + $hform->{'public'};
  my $pub_attrib = $public == 1 ? '0' : '1';

  my ($attacheddir) = get_attached_info($pub_attrib);

  my $notify = 0 + $hform->{'notification'};
  # 通知期間を登録するように修正
  my $notify_period = do {
    my ($y,$m,$d) = exists $hform->{'notify_period'} && $hform->{'notify_period'} ? split(/[\-\/]/,$hform->{'notify_period'}) : (0,0,0);
    ($y && $m && $d) ? timelocal(59, 59, 23, $d, $m - 1, $y - 1900) : '';
  };

  my $directlink = $hform->{'direct'} || '';
  $directlink =~ tr/ //d if($directlink);
  $directlink = uri_escape($directlink);
  my @cats = split /$split/,$hform->{'category'};
  my $cats = 0;
  foreach(@cats)
    {
      $cats |= $CATEGORIES{$_}{flag} if(exists $CATEGORIES{$_});
    }

  my $reserve = do {
    my ($y,$m,$d) = exists $hform->{'reserve'} && $hform->{'reserve'} ? split(/[\-\/]/,$hform->{'reserve'}) : (0,0,0);
    ($y && $m && $d) ? timelocal(59, 59, 23, $d, $m - 1, $y - 1900) : '';
  };

  my $body = $hform->{'body'};
  $body =~ s/&([a-z]+);/$CONVERT_TABLE{$1}/ig;
  $body =~ s/<\/?script.*?>//g;
  $body =~ s/<\/?object.*?>//g;
  $body =~ s/[\r\n]//g;

  my @images = ();
  for(0 .. $NUM_OF_IMAGES - 1)
    {
      my $keyname = (!$hform->{"image_$_->name"} && $_ == 0 && $hform->{'image->name'}) ? 'image' : "image_$_";
      my $image = $hform->{"$keyname->name"} ? saveFile($hform,$keyname,$attacheddir) : "";
      createSmallImage($image,$attacheddir) if($image);
      push @images,$image;
    }

  for(0 .. $at - 1)
    {
      if($hform->{"file_$_->name"})
        {
          my $a = saveFile($hform,"file_$_",$attacheddir,$_);
          my $an = $hform->{"file_name_$_"} ? $hform->{"file_name_$_"} : $a;

          $attached{$a} = $an;
          push(@attached_ord,$a);
        }
    }

  my $options = [];
  $options->[$_] = $hform->{"option_$_"} for(0 .. $#options);
  my $ctime = time;

  my $r = {
    'items' => [],
    'key'   => getLUID(),
    'title' => $hform->{'title'},
    'date'  => $hform->{'date'} || pl_strftime('%Y/%m/%d',localtime),
    'body'  => $body,
    'dkey'  => $DELETE_KEY ? $dkey : '',
    'options' => $options,
    'direct' => $directlink,
    'registed' => $ctime,
    'registdate' => $ctime,
    'lastupdate' => 0,
    'category' => $cats,
    'reserve'  => $reserve,
    'public' => $pub_attrib,
    'notify' => $notify,
    'notify_to' => $notify_period,
    'outline' => $outline,
    'headline' => $headline,
    'images' => [@images],
    'attached_ords' => [@attached_ord],
    'attached' => {%attached}
  };

  my $head = $alog->[0];

  $hlog->{$r->{key}} = create_record($r);

  if($locate == 1)
    {
      push @$alog,$r->{key};
    }
  else
    {
      $alog->[0] = $r->{key};
      unshift @$alog,$head;
    }

  updateLog($datafile);
  stdio::unlock($LOCK_NAME);

  # setting default values that stores to COOKIE.
  stdio::setCookie(\%cookie_default,"${DIR}_def",3600*24*60);

  delete_token($token);
  redirect(add_page("$CGI_SELF?dir=$DIR",'&'));
}

# delete key handler
sub onDk
{
  our ($DELETE_PHRASE,$L_KEY);
  return onShow() unless $DELETE_KEY;
  my $hform = FORM();

  my $index = $hform->{'index'};
  my $dkey = $hform->{'dkey'};
  my $md = $hform->{'md'};
  my $check = 0;

  if($dkey eq $DELETE_PHRASE)
    {
      $check = 1;
    }
  else
    {
      my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
      getLogEx($datafile,$L_KEY,$L_KEY,$index) || cgiOut(text('can not open file'),$LOCK_NAME);

      my $r = parse(LOG()->{$index});

      if($DELETE_KEY == 1)
        {
          $check = 1 if($r->{dkey} eq $dkey);
        }
      elsif($DELETE_KEY == 2)
        {
          $check = 1 if(md5crypt($dkey,$r->{dkey}) eq $r->{dkey});
        }
    }

  if($check)
    {
      my $dkey = session_value('dkey');
      $dkey = session_value('dkey',{}) unless($dkey);
      $dkey->{$index} = 1;
    }

  http_header(['Content-type: application/json']);
  print JSON->new->encode({'dir' => $DIR,'auth' => $check});
}

######################################################################
#削除キー認証が失敗したときの処理
######################################################################
sub delete_failure
{
  cgiOut(sprintf qq(<span class="message">%s</span><a href="$CGI_SELF?dir=$DIR">%s</a>),
                 text('delete key authentication was failed'),
                 text('click here and go back'));
}


######################################################################
# 保留設定に依存したファイル・移動処理
######################################################################
sub MoveFiles
{
  my ($r,$is_public) = @_;
  my ($attacheddir_public) = get_attached_info(1);
  my ($attacheddir_protected) = get_attached_info(0);
  my ($srcdir,$destdir) = $is_public ? ($attacheddir_protected,$attacheddir_public) : ($attacheddir_public, $attacheddir_protected);

  foreach(@{$r->{images}},@{$r->{attached_ords}})
    {
      my $src = "$srcdir/$_";
      my $src_s = "$srcdir/s/$_";
      my $destdir_s = "$destdir/s";

      move($src,$destdir);
      move($src_s,$destdir_s);
    }
}

######################################################################
# 現在の保留設定に依存したファイル・コピー処理
# 保留設定に寄らずコピー先は常に保留設定のディレクトリになる。
######################################################################
sub CopyFiles
{
  my $r = shift;
  my ($attacheddir_public) = get_attached_info(1);
  my ($attacheddir_protected) = get_attached_info(0);
  my ($srcdir,$destdir) = ($r->{public} ? $attacheddir_public : $attacheddir_protected, $attacheddir_protected);

  foreach(@{$r->{images}})
    {
      my $newfilename = create_filename('image',(fileparse($_, qr/\..*$/))[2]) if(length $_);

      my $src = "$srcdir/$_";
      my $src_s = "$srcdir/s/$_";
      if(-e $src)
        {
          copy($src,"$destdir/$newfilename");
          (-e $src_s) ? copy($src_s,"$destdir/s/$newfilename") : createSmallImage($newfilename,$destdir);
        }
      $_ = $newfilename;
    }

  foreach(@{$r->{attached_ords}})
    {
      my $newfilename = create_filename('file',(fileparse($_, qr/\..*$/))[2]);
      my $src = "$srcdir/$_";
      my $src_s = "$srcdir/s/$_";
      copy($src,"$destdir/$newfilename") if(-e $src);

      $r->{attached}{$newfilename} = $r->{attached}{$_};
      $_ = $newfilename;
    }
}

1;

