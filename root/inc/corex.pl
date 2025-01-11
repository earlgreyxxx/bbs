#!/usr/bin/perl
use strict;
use warnings;
use lib qw|./site-lib|;
no strict qw/refs/;
no warnings qw/once uninitialized/;

our (%COOKIE,$NUM_OF_IMAGES,$L_OPTION_START);
our ($DIR,$FDIR,$DIR_DEFAULT,$split,$split2,$DIR_DATA,$DIR_PASSWORD,$VDIR_DATA,%SESSION_PARAMS);
our (@CATEGORIES,%CATEGORIES);

my (@FORM,%FORM);
my (@LOG,%LOG);
my $TOKEN_EXPIRE = 10800;
my $COOKIE_TOKEN_EXPIRE = 900;

use IO::File;
use IO::Dir;
use Data::Dumper;
use Digest::MD5 qw/md5_hex/;
use JSON;
use File::Copy;
use File::Basename qw/fileparse basename/;
use Session;
use POSIX;

# 初期化＆パラメータ読込
sub initialize
{
  our ($MAX_UPLOAD_SIZE,$IMAGELIB,$DIR_TEMPORARY,%urlpath);

  Session::init(%SESSION_PARAMS);

  my ($hform,$aform) = FORMS();

  # 最大アップロードサイズの決定
  $stdio::max_byte = $MAX_UPLOAD_SIZE;

  my $ws = shift || 0;
  if(exists $ENV{'REQUEST_METHOD'})
    {
      my $dir_tempo = "$DIR_TEMPORARY/";
      unless($ws)
        {
          undef $dir_tempo;
          $ws = 2;
        }
      @$aform = stdio::getFormData($hform,$ws,'UTF8',$split,$dir_tempo);
    }
  else
    {
      foreach(@ARGV)
        {
          my ($k,$v) = split /=/;
          $hform->{$k} = $v;
          push @$aform,$k;
        }

      my %hashes = ('form.txt' => $hform,'cookie.txt' => \%COOKIE);
      while(my ($file,$hash) = each(%hashes))
        {
          getHashData($file,
                      $hash,
                      $file eq 'form.txt' ? $aform : undef);
        }
    }

  $DIR = $hform->{'dir'} ? $hform->{'dir'} : $DIR_DEFAULT;

  #$FDIR is compatibility variable.
  $Session::DIR = $FDIR = $DIR;

  $hform->{'dir'} = $DIR = ($urlpath{isrewrite} ? basename($urlpath{request_vdir}) : $DIR_DEFAULT) unless($DIR);
  unless(-e "$DIR_DATA/$DIR/property.pl")
    {
      http_header(['Status: 500 Internal Server Error','Content-type: text/html; charset=UTF-8' ]);
      print qq(<html><head><title>Start up error</title></head><body>can not detect data directory</body></html>\n);
      cgiExit();
    }

  &module_initialize;
}

sub module_initialize
{
  our ($IMAGELIB,$LOGTYPE,$IMAGE_WIDTH);
  our ($L_KEY,$L_TITLE,$L_DATE,$L_BODY,$L_ATTR,$L_FILE,$L_DELETE,$L_OPTION_START);

  require "$DIR_DATA/$DIR/property.pl";

  %CATEGORIES = map { $_->{value},$_ } @CATEGORIES;

  # ログデータの保持方法により、create_record,parse,getLogEx関数を決定する。
  # pass $L_.... to module
  $LOGTYPE || die "Empty LOGTYPE";
  eval <<__CODE__;
use $LOGTYPE;
${LOGTYPE}::init(\\\&toLOG,\$split,\$split2,\$NUM_OF_IMAGES);
${LOGTYPE}::inject(\$L_KEY,\$L_TITLE,\$L_DATE,\$L_BODY,\$L_ATTR,\$L_FILE,\$L_DELETE,\$L_OPTION_START) if(${LOGTYPE}->can('inject'));
__CODE__
  $@ && die $@;

  #画像縮小のためのライブラリ決定
  my $libname = $IMAGELIB || 'NO';
  $libname =~ s/:://g;
  eval <<__CODE__;
use Thumbnail::$libname;
\$Thumbnail::${libname}::IMAGE_WIDTH = \$IMAGE_WIDTH;
__CODE__
  $@ && die $@;
}

#公開できる状態かどうか？
sub can_open_public
{
  parse(shift,1)->{public} || validate_session($DIR_PASSWORD);
}

#公開可能かつ直リンク設定以外
sub can_open_public_not_direct
{
  my ($direct,$public) = @{parse(shift,1)}{'direct','public'};

  return !$direct if(validate_session($DIR_PASSWORD));
  return !$direct && $public;
}

#カテゴリ指定かつ公開可能かつ直リンク設定以外
sub category_can_open_public_not_direct
{
  my ($direct,$public,$category) = @{parse(shift,1)}{'direct','public','category'};
  my $cat = int FORMVALUE('cat');

  return unless(exists $CATEGORIES{$cat});
  return !$direct && ($category & $CATEGORIES{$cat}{flag}) == $CATEGORIES{$cat}{flag} if(validate_session($DIR_PASSWORD));
  return !$direct && $public && ($category & $CATEGORIES{$cat}{flag}) == $CATEGORIES{$cat}{flag};
}

#公開可能かつ見出し出力可能
sub can_open_public_and_headline
{
  my ($public,$headline) = @{parse(shift,1)}{'public','headline'};

  return $public && $headline;
}

sub make_headline_filter
{
  my $limit = shift || die 'invalid arguments were given at make_headline_filter';
  my $count = 0;
  return sub {
    my ($public,$headline) = @{parse(shift,1)}{'public','headline'};

    return 0 unless($public && $headline);
    return ++$count < $limit ? 1 : -1;
  };
}

### exitの代替
sub cgiExit
{
  session_end();
  do 'finalize.pl';
  exit;
}

#MD5による疑似crypt関数
sub md5crypt
{
  my ($plain,$seed) = @_;
  $seed = stdio::getRandomString(8) unless($seed);
  $seed = substr($seed,0,8) if(length $seed > 8);

  sprintf('%s!%s',$seed,md5_hex($plain.$seed));
}

sub generate_token
{
  my $tokens_name = shift || 'tokens';
  my $token = sha1_hex(time . crypt(stdio::getRandomString(8),stdio::getRandomString(2)));

  session_value($tokens_name,{}) unless(session_value($tokens_name));
  session_value($tokens_name)->{$token} = time;

  $token;
}

#clean up tokens
sub clear_tokens
{
  my $tokens_name = shift || 'tokens';
  if(my $tokens = session_value('tokens'))
    {
      foreach(keys %$tokens)
        {
          my $delta = time - $tokens->{$_};
          delete $tokens->{$_} if($delta > $TOKEN_EXPIRE);
        }
    }
}

sub verify_token
{
  my ($token,$tokens_name) = @_;
  return unless $token;

  $tokens_name = 'tokens' unless $tokens_name;
  my $tokens = session_value($tokens_name);

  $tokens && defined $tokens && $token && exists $tokens->{$token} && ($TOKEN_EXPIRE >= time - $tokens->{$token}) ;
}

sub delete_token
{
  my ($token,$tokens_name) = @_;
  return unless $token;

  $tokens_name = 'tokens' unless $tokens_name;
  my $tokens = session_value($tokens_name);

  delete $tokens->{$token};
}

sub publish_token
{
  my $tokens_name = shift || 'tokens';
  my $token = generate_token($tokens_name);
  my $cookie = "token=$token";

  stdio::setCookie(\$cookie,'tn',$COOKIE_TOKEN_EXPIRE);
  $token;
}

sub close_token
{
  my ($token,$tokens_name) = @_;
  return unless $token;

  my $cookie = "token=$token";
  stdio::setCookie(\$cookie,'tn',-1);

  delete_token($token,$tokens_name);
}

#削除キー認証(未実装)
sub delete_auth
{
  return 1;

  my $index = shift || return;

  session_delete_value('dkey');
}

##添付ファイルの位置を返す
#引数：公開(真)・非公開(偽)
sub get_attached_info
{
  our ($DIR_ATTACHED,$ATTACHED_NAME,$VDIR_ATTACHED,$DIR_PROTECTED_NAME);
  my $public = shift;

  my $attacheddir = length($DIR_ATTACHED) > 0 ? $DIR_ATTACHED : "$DIR_DATA/$FDIR/$ATTACHED_NAME";
  my $attachedvdir = length($DIR_ATTACHED) > 0 ? (length($VDIR_ATTACHED) > 0 ? $VDIR_ATTACHED : $DIR_ATTACHED)
                                               : (length($VDIR_ATTACHED) > 0 ? $VDIR_ATTACHED : "$VDIR_DATA/$FDIR/$ATTACHED_NAME");

  map { $_ .= "/$DIR_PROTECTED_NAME"; } ($attacheddir,$attachedvdir) unless($public);

  mkdir $attacheddir;
  mkdir $attacheddir . '/s';

  $attacheddir,$attachedvdir;
}

#データの列挙
sub getDataNames
{
  my $dirpath = shift || return;
  my $dh = IO::Dir->new($dirpath) || return;
  my %children = map {
    if($_ and $_ ne '.' and $_ ne '..' and -d "$dirpath/$_" and -f "$dirpath/$_/property.pl")
      {
        my $value = getVariable("$dirpath/$_/property.pl",'\$HTML_TITLE') || $_;
        $_,$value;
      }
    else
      {
        '','';
      }
  } $dh->read;
  $dh->close;

  my %rv;
  if(%children)
    {
      while(my ($k,$v) = each %children)
        {
          $rv{$k} = $v if($k);
        }
    }
  return %rv;
}

#ジャンプメニュー出力
sub getJumpMenu
{
  our (@ORDER_DIR,$CGI_ADMIN);
  my %dd = getDataNames($DIR_DATA);
  return unless(%dd);

  my @dd = keys %dd;
  return if(@dd <= 1);

  @ORDER_DIR = sort { $dd{$a} cmp $dd{$b} } @dd if(@ORDER_DIR <= 0);
  my @dropdownitems = map {
    my $active = $_ eq $FDIR ? ' active' : '';
    qq(<a class="dropdown-item$active" href="$CGI_ADMIN?dir=$_">$dd{$_}</a>);
  } @ORDER_DIR;

  return unless(@dropdownitems);

  my @rv = ();
  push @rv,qq(<li class="nav-item dropdown">);
  push @rv,qq(  <a class="nav-link dropdown-toggle" href="#" id="navbarDropdownMenuLink" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">);
  push @rv,text(q(Other directories));
  push @rv,qq(  </a>);
  push @rv,qq(  <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">);
  push @rv,@dropdownitems;
  push @rv,qq(  </div>);
  push @rv,qq(</li>);

  return join "\n",@rv;
}

=pod
=encoding UTF-8
=head1 sub applyTemplateHtml(テンプレートとなるファイル名,格納するスカラ変数へのリファレンス)
ファイルを読み込んで ($xxx)部分を変数展開したものを格納します。
=cut
sub applyTemplateHtml
{
  my ($file,$file_contents) = @_;
  my $file_size = -s $file;
  my $fin = IO::File->new($file) || return;
  $fin->read($$file_contents,$file_size);
  $fin->close;

  $$file_contents =~ s/\$(\w+?)\[(\d+?)\]/${$1}[$2]/g;
  $$file_contents =~ s/\$(\w+?)\[\$(\w+?)\]/${$1}[${$2}]/g;
  $$file_contents =~ s/\$(\w+?)\{\$(\w+?\[\d+?\])\}/${$1}{$2}/g;
  $$file_contents =~ s/\$(\w+?)\{'(.+?)'\}/${$1}{$2}/g;
  $$file_contents =~ s/\$(\w+)/${$1}/g;

  return 1;
}

sub getFilesizeString
{
  my $file = shift;
  my $size = -s $file;

  if($size >= 1048576)
    {
      $size = int($size / 1048576);
      return "${size}MB";
    }
  elsif($size >= 1024)
    {
      $size = int($size / 1024);
      return "${size}KB";
    }
  else
    {
      return "${size}バイト";
    }
}


#アップロードされたファイルの拡張子を返す。
sub getExtension
{
  my ($r_form,$name) = @_;

  my $ext;
  my $pos = rindex($r_form->{"$name->name"},'.');

  if($r_form->{"$name->type"} =~ m/image\/p?jpeg/i)
    {
      $ext = '.jpg';
    }
  elsif($r_form->{"$name->type"} =~ m/image\/gif/i)
    {
      $ext = '.gif';
    }
  elsif($r_form->{"$name->type"} =~ m/image\/.*(png).*/i)
    {
      $ext = '.png';
    }
  elsif($pos > 0)
    {
      $ext = substr($r_form->{"$name->name"},$pos);
      $ext = lc($ext);
    }
  else
    {
      $ext = '.dat';
    }

  return $ext;

}


#ファイル名を生成
sub create_filename
{
  my ($prefix,$suffix) = @_;
  $prefix = 'file' unless($prefix);

  my $rv = sprintf('%s%d%s',$prefix,time,stdio::getRandomString(2,'0123456789abcdef'));
  $rv .= $suffix if($suffix);

  return $rv;
}

#ファイルを保存
sub saveFile
{
  my ($r_form,$name,$dir,$i) = @_;
  my $filename;
  my $ext = getExtension($r_form,$name);

  my $basename = create_filename($name =~ /^image(_\d+)?$/ ? 'image' : 'file');

  if(defined $i)
    {
      if(($r_form->{"myfilename_$i"} eq '2') && (length $r_form->{"system_file_name_$i"} > 0))
        {
          $filename = $r_form->{"system_file_name_$i"} . $ext;

          if(($r_form->{"system_file_name_$i"} =~ m/[^a-z0-9_\-\.]/i) || -e "$dir/$filename")
            {
              $filename = $basename . $ext;
            }
        }
      else
        {
          $filename = $basename . $ext;
        }
    }
  else
    {
      $filename = $basename . $ext;
    }

  move($r_form->{$name},"$dir/$filename");

  return $filename;
}

#ごみ掃除 エラーなどで残ったファイルを削除
# 一時ファイルの寿命は 3分=180秒 として計算。
sub processGarbage
{
  our $TTL;
  my $dirpath = shift;
  my $dh = IO::Dir->new($dirpath) || return;
  foreach($dh->read)
    {
      next if(m/^\./ || -d);
      my $d = -M "$dirpath/$_";

      unlink("$dirpath/$_") if($d * 86400 > $TTL);
    }
  $dh->close;
}

###################################################
# ファイルから任意の値を取得
###################################################
sub getVariable
{
  my ($file,$var) = @_;
  my $retVal;

  my $fin = IO::File->new($file) || return;
  while(defined(local $_ = $fin->getline))
    {
      s/[\r\n]//g;
      if(m/^(?:our\s+)?$var\s*=\s*[\'\"]*(.*)[\'\"]\s*;$/)
        {
          $retVal = "$1";
          last;
        }
    }
  $fin->close;

  return (length $retVal > 0 ? $retVal : 0);

}

#リンク時にオプションを別ファイルから読む。
sub readOptions
{
  my $file = shift;
  my @ret;
  my @tag;
  my $fin = IO::File->new($file) || return;

  while(defined(local $_ = $fin->getline))
    {
      chomp;
      s/\s//g;

      if(/(\$DIR_ATTACHED)=(.*);/)
        {
          $ret[0] = $2;
          $ret[0] =~ s/[\'\"]//g;
        }

      if(/(\$VDIR_ATTACHED)=(.*);/)
        {
          $ret[1] = $2;
          $ret[1] =~ s/[\'\"]//g;
        }

      if(/(\$DELETE_KEY)=(.*);/)
        {
          $ret[2] = $2;
        }

      if(/(\@TAG)=(.*);/)
        {
          my $t = $2;
          $t =~ s/[\'\"\(\)]//g;
          @tag = split(/,/,$t);
        }
    }
  $fin->close;

  push(@ret,@tag);
  return @ret;
}

#####ページ・ナビゲーション##########
sub navigator
{
  our ($CGI_SELF,$NAVI_IS_PAGINATION,$NAVI_PREV,$NAVI_NEXT,$PAGE_MAX,$ADMIN_NAVI_PREV,$ADMIN_NAVI_NEXT);
  return &pager(@_) if(defined $NAVI_IS_PAGINATION && $NAVI_IS_PAGINATION);

  my ($page,$lognum,$is_admin) = @_;
  my $next = 1 + $page;
  my $prev = $page - 1;
  my $prev_str = $prev > 1 ? "&page=$prev" : '';
  my $navi = $is_admin ? [$ADMIN_NAVI_PREV,$ADMIN_NAVI_NEXT] : [$NAVI_PREV,$NAVI_NEXT] ;
  my ($nprev,$nnext) = @$navi;

  my $hform = FORM();

  my $prefix = "dir=$DIR";
  $prefix .= "&cat=$hform->{'cat'}" if(exists $hform->{'cat'} && exists $CATEGORIES{$hform->{'cat'}});
  my @html = ();
  push @html,qq(  <li class="btn btn-primary prev"><a href="$CGI_SELF?$prefix$prev_str">$nprev</a></li>) if($prev > 0);
  push @html,qq(  <li class="btn btn-primary next"><a href="$CGI_SELF?$prefix&page=$next">$nnext</a></li>) if($page * $PAGE_MAX < $lognum);

  if(@html)
    {
      print qq(<ul class="btn-group paging">\n);
      print join("\n",@html),"\n";
      print qq(</ul>\n);
    }
}

sub pager
{
  our ($CGI_SELF,$PAGE_MAX,$PAGE_DELTA,$NAVI_NEXT,$NAVI_PREV);
  my ($page,$lognum) = @_;
  my $hform = FORM();

  my $start = 1;
  my $max = int($lognum / $PAGE_MAX);
  $max++ if($lognum % $PAGE_MAX > 0);
  my ($begin,$end) = ('','');
  my $prefix = "dir=$DIR";
  $prefix .= "&cat=$hform->{'cat'}" if(exists $hform->{'cat'} && exists $CATEGORIES{$hform->{'cat'}});

  if($max > $PAGE_DELTA * 2 + 1)
    {
      my $limit = $max;
      if($page > $PAGE_DELTA)
        {
          if($page <= $limit - $PAGE_DELTA)
            {
              $start = $page - $PAGE_DELTA;
              $max = $page + $PAGE_DELTA;
            }
          else
            {
              $start = $limit - $PAGE_DELTA * 2;
            }
        }
      else
        {
          $max = $PAGE_DELTA * 2 + 1;
        }

      $begin = qq(<li class="page-item"><a class="page-link" href="$CGI_SELF?$prefix&page=1" title="1">$NAVI_PREV</a></li>\n) if($page > $PAGE_DELTA + 1);
      $end = qq(<li class="page-item"><a class="page-link" href="$CGI_SELF?$prefix&page=$limit" title="$limit">$NAVI_NEXT</a></li>\n) if($page < $limit - $PAGE_DELTA);
    }

  print qq(<ul class="pagination justify-content-center">\n);
  print $begin;
  for($start .. $max)
    {
      my $class = ' class="page-item' . ($_ == $page ? ' active' : '') . '"';
      my $page_str = $_ > 1 ? "&page=$_" : '';

      print qq(<li$class>);
      print $_ == $page ? qq(<span class="page-link">$_</span>) :  qq(<a class="page-link" href="$CGI_SELF?dir=$DIR$page_str">$_</a>);
      print qq(</li>\n);
    }
  print $end;
  print qq(</ul>\n);
}

# セッションに記録したページを引数文字列にして付加して返す。
sub add_page
{
  my ($url,$delim) = @_;
  $delim = '' unless(defined $delim);

  my $page = session_value('page');
  my $rv = '';

  return $url . ($page > 1 ? "${delim}page=$page" : '');

  return $rv;
}


sub html_show_all
{
  our ($NAVI_ALL,$CGI_USER);
  print qq(<p class="commands"><a href="${CGI_USER}?dir=$DIR" class="submit-show-all">$NAVI_ALL</a></p>\n);
}


###################################################
# HTTPヘッダー出力
# 引数がリファレンスなら出力ヘッダー配列
# 引数がスカラー値なら出力文字コード指定
###################################################
sub http_header
{
  my $headers = shift;

  if(ref $headers eq 'ARRAY')
    {
      $headers = 'Content-type: text/html' unless(@$headers);
      print join("\n",@$headers),"\n" x 2;
    }
  else
    {
      my $content_type = sprintf 'Content-type: text/html; charset=%s',$headers ? $headers : 'UTF-8';
      print $content_type,"\n" x 2;
    }
}

sub http_header_500
{
  my ($additionals, $headers) = (shift || ['content-type: text/html; charset=UTF-8'],['Status: 500 Internal Server Error']);
  push @$headers,@$additionals if(ref $additionals eq 'ARRAY' && @$additionals > 0);

  http_header($headers);
}


###################################################
# HTTPヘッダー出力(クッキー)
###################################################
sub html_cookie
{
  our $COOKIE_NAME;
  my @headers = @_;
  stdio::setCookie(\%COOKIE,$COOKIE_NAME,'');
  print "\n";
  http_header(\@headers);
}

#ここよりよく使うサブサブルーチン集。

##################################################################
#
# 日付などより、ローカルユニーク名を得る。
#
##################################################################
sub getLUID
{
  my $ctime = time();
  my @rd;
  my $str = '0123456789abcdef';

  $rd[0] =stdio::getRandomString(12,$str);
  $rd[1] =stdio::getRandomString(4,$str);
  $rd[2] =stdio::getRandomString(4,$str);
  $rd[3] =stdio::getRandomString(4,$str);

  my $rd = join('-',@rd);

  return  "${rd}-${ctime}";
}

sub getUnique
{
  return sprintf('%s-%010d',stdio::getRandomString(8),getScramble(time));
}

# 数字を受取り、スクランブルして返す。
sub getScramble
{
  use integer;

  my $v = shift;
  # 奇数その1の乗算
  $v *= 0x1ca7bc5b;
  $v &= 0x7FFFFFFF; # 下位31ビットだけ残して正の数であることを保つ

  # ビット上下逆転
  $v = ($v >> 15) | (($v & 0x7FFF) << 16);

  # 奇数その2（奇数その1の逆数）の乗算
  $v *= 0x6b5f13d3;
  $v &= 0x7FFFFFFF; # 下位31ビットだけ残して正の数であることを保つ

  # ビット上下逆転
  $v = ($v >> 15) | (($v & 0x7FFF) << 16);

  # 奇数その1の乗算
  $v *= 0x1ca7bc5b;
  $v &= 0x7FFFFFFF; # 下位31ビットだけ残して正の数であることを保つ

  return $v;
}

###ページリダイレクト#######
# $location : 転送先　　$expire : クッキー有効秒数
############################
sub redirect
{
  our ($COOKIE_NAME,$LOCK_NAME);
  my ($location,$expire,$lock) = @_;

  stdio::unlock($LOCK_NAME) if($lock);
  stdio::setCookie(\%COOKIE,$COOKIE_NAME,$expire) if($expire);

  print "Expires: -1\n";
  print "Pragma: no-cache\n";
  print "Cache-Control: no-cache\n";
  print "Location: $location\n\n";

  cgiExit();
}

###ホスト名を返す###########
# $addr : IPアドレス
############################
sub getRemoteHost
{
  my ($addr) = @_;
  my $host;

  $host =  gethostbyaddr(pack("C4", split(/\./, $addr)), 2);

  unless($host)
    {
      $host = $addr;
    }

  return $host;
}

# DBI 接続をプール##########
my %DBH = ();
sub getDbConnection
{
  my $params = shift;
  if(!defined $DBH{$params->{dsn}})
    {
      $DBH{$params->{dsn}} = eval
        {
          return DBI->connect($params->{dsn},$params->{user},$params->{password});
        };
      if($@)
        {

        }
    }
  return $DBH{$params->{dsn}};
}

###################################################
# 現在の%LOGと@LOGを使ってログを更新
###################################################
sub updateLog
{
  our ($DIR_TEMPORARY,$LOCK_NAME,$LOGTYPE);
  my ($logfile,$tempfile,$alog,$hlog) = @_;
  $tempfile = "$DIR_TEMPORARY/temp.$FDIR.$$" unless $tempfile;
  $alog = LOG(1) if(!$alog || ref $alog ne 'ARRAY');
  $hlog = LOG() if(!$hlog || ref $hlog ne 'HASH');

  my $fout = IO::File->new(">$tempfile") || cgiOut(text('can not open file'),$LOCK_NAME);
  my $head = $alog->[0];
  $fout->print($hlog->{$head},"\n");
  foreach(@{$alog}[1 .. $#$alog])
    {
      writeLine($fout,$hlog,$_) if(exists $hlog->{$_});
    }

  $fout->close && move($tempfile,$logfile);
}

###################################################
# 生ログデータを読み込んでヘッダをハッシュに格納
###################################################
sub getLogHeader
{
  my $filename = shift;
  my ($hlog,$alog) = LOGS();

  -e $filename || return 0;
  my $fin = IO::File->new($filename) || cgiOut(text('can not open file'));

  LOG_CLEAR();

  my $header = $fin->getline;
  $header =~ s/[\r\n]//g;
  my ($key,$other) = split /$split/,$header,2;
  $hlog->{$key} = $header;
  push @$alog,$key;

  $fin->close;
  1;
}

=com
 生ログデータからログ先頭部分のカラム配列を返す
 リストコンテキストでは配列を、スカラーコンテキストではリファレンスを返す。
=cut
sub getLogColumns
{
  my ($hLog,$aLog,$isShift) = @_;
  $isShift = 0 unless(defined $isShift);
  ($hLog,$aLog) = LOGS() if(!$hLog || !$aLog || ref $hLog ne 'HASH' || ref $aLog ne 'ARRAY');

  my @rv = split /$split/,$hLog->{$isShift ? shift(@$aLog) : $aLog->[0]};
  wantarray ? @rv : [@rv];
}

sub getOptionColumns
{
  my ($hLog,$aLog) = @_;
  my @headers = getLogColumns($hLog,$aLog);

  my @rv = (getLogColumns($hLog,$aLog))[$L_OPTION_START .. $#headers];
  wantarray ? @rv : [@rv];
}

sub getOptionColumnsFromHeader
{
  my @rv = @{$_[0]}[$L_OPTION_START .. $#{$_[0]}];
  wantarray ? @rv : [@rv];
}

# グローバル変数 *LOG に保存する
# argument 1st is key and 2nd is hash of parsed value.
sub toLOG
{
  my ($hlog,$alog) = LOGS();
  return if(exists $hlog->{$_[0]});

  $hlog->{$_[0]} = $_[1];
  push @$alog,$_[0];
}

###################################################
# 年度(下2桁)、月から西暦年を得る
###################################################
sub getYear
{
  my ($byear,$mon) = @_;
  return  ($mon < 4) ? $byear + 2000 + 1 : $byear + 2000;
}

###################################################
# カテゴリを取得
###################################################
sub getCategories
{
  my ($cat,@category_list) = @_;
  return map { $_->{tag} } grep { ($cat & $_->{flag}) == $_->{flag} } @category_list;
}

###################################################
# メッセージ出力用
###################################################
sub MessageOut
{
  our ($HEADER_STRING,$FOOTER_STRING);
  my ($title,$str1,$str2,$str3,$str4,$str5) = @_;

  http_header();
  html_start("Message:CGI.");

  print <<EOI;
<table width="100%" height="90%"><tr><td valign="middle">
$HEADER_STRING
<p style="font-size:24px;color:#FF6600" align="center"> $title </p>
<p style="font-size:14px" align="center">
$str1 <br><br>
$str2$str3$str4$str5
</p>
$FOOTER_STRING
<br>
</td></tr></table>
EOI

  html_end();
  cgiExit();
}

###################################################
# エラー出力用
###################################################
sub cgiOut
{
  our ($HEADER_STRING,$FOOTER_STRING,$debug_mode);
  my($str,$lock) = @_;

  stdio::unlock($lock) if($lock);

  http_header_500();
  html_start("Message:CGI.");

  print <<EOI;
<div class="container error-message">
  <p class="error-header">$HEADER_STRING</p>

  <p class="error-title"> Error Message... </p>
  <p>$str</p>
  <p><a href="javascript:history.back();">go back</a></p>
EOI
  #########################
  if($debug_mode == 1)
    {
      print <<__HTML__;

  <div class="error-debug">
    <p class="error-debug-title">Below is the DEBUG_MODE output string...</p>
    <blockquote>
      <xmp class="error-debug-formdata">
__HTML__

      my ($hform,$aform) = FORMS();
      foreach(@$aform)
        {
          if($hform->{"$_->name"})
            {
              print qq($_->name = $hform->{"$_->name"}\n);
              print qq($_->type = $hform->{"$_->type"}\n);
              print qq($_->path = $hform->{"$_->path"}\n);
              #print qq($_ = $hform->{$_}\n);
            }
          else
            {
              print "$_ = $hform->{$_}\n";
            }
        }
      print <<__HTML__;
      </xmp>
      <xmp class="error-debug-apache">
__HTML__

      foreach(keys(%ENV))
        {
          print "$_ = $ENV{$_}\n";
        }

      print <<__HTML__;
      </xmp>
    </blockquote>
__HTML__

    }

#########################
  print <<EOI;
  <p class="error-footer">$FOOTER_STRING</p>
</div>
EOI

  html_end();
  cgiExit();
}

###################################################
# メッセージ文字列の取得
###################################################
sub text
{
  no strict 'refs';
  my ($str,$lang) = @_;
  $lang = 'ja' if(!defined $lang || length $lang == 0);

  my $text = *{"TEXT_$lang"}{HASH};
  $str =~ s/\.+$//g;
  return defined $text->{$str} ? $text->{$str} : $str;
}
sub _E
{
  my ($str,$before,$after) = @_;
  $before = '' unless defined $before;
  $after = '' unless defined $after;

  print $before,text($str,'ja'),$after;
}

##################################################
# ログを取得
#  引数： 1 -> 配列
##################################################
sub LOG
{
  # our (@LOG,%LOG);
  (shift) ? \@LOG : \%LOG;
}
sub LOGS
{
  # our (@LOG,%LOG);
  \%LOG,\@LOG;
}
# ログクリア
sub LOG_CLEAR
{
  # our (@LOG,%LOG);
  @LOG = ();
  %LOG = ();

  \%LOG,\@LOG;
}

##################################################
# リクエストパラメーターを取得
#  引数： 1 -> 配列
##################################################
sub FORM
{
  # our (@FORM,%FORM);
  (shift) ? \@FORM : \%FORM;
}
sub FORMS
{
  \%FORM,\@FORM;
}
sub FORMVALUE
{
  my $name = shift;
  my ($h,$a) = FORMS();
  (defined $name && length $name) || return @$a;

  exists($h->{$name}) ? $h->{$name} : '';
}
sub FORMNAMES
{
  return FORMVALUE();
}
sub FORMVALUES
{
  return unless(@_);
  my $h = FORM();
  map { $h->{$_} } @_;
}

sub FDIR
{
  return $FDIR;
}
sub DIR
{
  return $DIR;
}


###################################################
# 定義していない、かつ空の文字列
###################################################
sub is_defined_and_not_empty
{
  my $val = shift;
  defined $val && length $val > 0;
}
sub is_exists_and_not_empty
{
  my ($key,$hash) = @_;
  exists $hash->{$key} && length $hash->{$key};
}

###################################################
# for debugging use.
###################################################
sub debugOut
{
  print 'Cotent-type: text/plain',"\n\n";
  print Dumper($_[0]);
  cgiExit();
}
sub Dumper_html
{
  printf '<pre>%s</pre>',Dumper($_);
}

###################################################
# wrapper for pl_strftime
###################################################
sub getstrftime
{
  my ($utime,$fmt) = @_;
  $utime = time if(!defined $utime || !$utime);
  $fmt = '%Y年%m月%d日(%J) %H時%M分%S秒' if(!defined $fmt || !$fmt);

  pl_strftime($fmt,localtime($utime));
}

###################################################
# wrapper for POSIX::strftime (japanese week string)
###################################################
sub pl_strftime
{
  # to do %A to 日本語
  my ($fmt,@time) = @_;
  my @week_ja = qw(日 月 火 水 木 金 土);
  if(@time == 1)
    {
      @time = localtime($time[0])
    }
  elsif(!@time)
    {
      @time = localtime;
    }

  $fmt =~ s/\%J/$week_ja[$time[6]]/g;

  return POSIX::strftime($fmt,@time);
}

1;
