#!/usr/bin/perl
use strict;
use warnings;

no warnings 'uninitialized';

our (%COOKIE,$DIR,$FDIR,$DIR_DATA,$VDIR_DATA,$NUM_OF_IMAGES);
our ($CGI_SELF,$CGI_FMANAGER);
our ($URL_CONTENT,$VERSION,$DELETE_KEY);
our (@TAG,$IMG_CGI,$IMAGE_WIDTH,@NOTIFICATION,@NOTIFICATION_DISP,$DATE_TITLE);
our ($ICON_CLEARDATE,$ICON_ADD,$ICON_FMANAGER,$ICON_SUBMIT_MODIFY,$ICON_INCRESE_UPLOAD,$ICON_SUBMIT_POST);
our ($LOG_NAME,$ICON_BACK,$ARTICLE_WIDTH,$ICON_ORDER_BOTTOM,$ICON_ORDER_DOWN,$ICON_ORDER_UP,$ICON_ORDER_TOP);
our ($ICON_LINK,$TITLE_CLONE_DESC,$ICON_COPY,$TITLE_ADD_COPY,$ICON_ADD_COPY,$ICON_MODIFY,$ICON_ARTICLE);
our ($IMAGE_LINK,$ICON_REMOVE);
our (@CATEGORIES,%CATEGORIES);

##########################################################
#管理画面用のヘッダー
##########################################################
sub html_admin_start
{
  my ($str,$rsubs,$body_class) = @_;
  $body_class = length $body_class ? sprintf(' class="%s"',$body_class) : '';

  print <<__HTML__;
<!doctype html>
<html lang="ja">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
<title>UPDATE 管理画面</title>
<link rel="stylesheet" type="text/css" href="$URL_CONTENT/bootstrap/css/bootstrap.min.css?v=$VERSION" />
<link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/admin.css?v=$VERSION" />
<link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/button.css?v=$VERSION" />
<script src="$URL_CONTENT/js/jquery-3.3.1.min.js"></script>
<script src="$URL_CONTENT/js/popper.min.js"></script>
__HTML__

  foreach(@$rsubs) { &$_ if(ref $_ eq 'CODE'); }

print <<__HTML__;
</head>
<body$body_class>
__HTML__

  html_admin_nav();

print <<__HTML__;
<div id="main">
__HTML__

  1;
}


##########################################################
#管理画面用のフッター
##########################################################
sub html_admin_end
{
  my @rsubs = @_;

  print "</div>\n";

  foreach(@rsubs) { &$_ if(ref $_ eq 'CODE'); }

  print <<EOI;
  <script src="$URL_CONTENT/bootstrap/js/bootstrap.min.js"></script>
</body>
</html>
EOI
}

##########################################################
# 管理画面メニュー
##########################################################
sub html_admin_nav
{
  our ($CGI_SIGNIN,$ICON_LOGOUT,$ICON_NEW,$ICON_DOCS,$HTML_TITLE);
  my %cookie = ();
  stdio::getCookie(\%cookie,'DP');
  my $dp = $cookie{dp} || 'article';
  my %dpClass = ($dp => ' active');
  my $url_self = add_page("$CGI_SELF?dir=$DIR",'&');

  print <<__HTML__;
  <nav class="navbar navbar-expand-md navbar-dark bg-dark fixed-top">
    <a class="navbar-brand" href="$CGI_SELF?dir=$DIR">$HTML_TITLE</a>
    <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarsAdmin" aria-controls="navbarsExampleDefault" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarsAdmin">
      <ul class="navbar-nav mr-auto">
        <li class="nav-item"><a class="nav-link" href="$CGI_SELF?mode=post&ac=show&dir=$DIR">$ICON_NEW</a></li>
        <li class="nav-item"><a class="nav-link" target="_blank" href="$URL_CONTENT/docs.pdf">$ICON_DOCS</a></li>
        @{[getJumpMenu()]}
        <li class="nav-item dropdown">
         <a class="nav-link dropdown-toggle" href="#" id="navbarDropdownMenuLink" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">@{[ text('Show by') ]}</a>
          <div class="dropdown-menu" aria-labelledby="navbarDropdownMenuLink">
            <a class="dropdown-item$dpClass{'article'}" href="$url_self&dp=article">@{[ text('By article') ]}</a>
            <a class="dropdown-item$dpClass{'list'}" href="$url_self&dp=list">@{[ text('By list') ]}</a>
          </div> 
        </li>
      </ul>
      <ul class="navbar-nav m-0">
        <li class="nav-item"><a class="nav-link" href="$CGI_SIGNIN?dir=$DIR&mode=logout">$ICON_LOGOUT</a></li>
      </ul>
    </div>
  </nav>
__HTML__
}

##########################################################
#管理画面用のHEAD内要素に挿入
##########################################################
sub html_head_show
{
  print <<__HTML__;
<link rel="stylesheet" type="text/css" href="$URL_CONTENT/lightbox2/css/lightbox.css?v=$VERSION" />
__HTML__
}

sub html_foot_show
{
  print <<__HTML__;
<script type="text/javascript" src="$URL_CONTENT/js/include.js?v=$VERSION"></script>
<script type="text/javascript" src="$URL_CONTENT/lightbox2/js/lightbox.min.js?v=$VERSION"></script>
__HTML__
}

sub html_head_edit
{
  print <<__HTML__;
<script type="text/javascript"><!--
var SCRIPT_DIR = '$URL_CONTENT/css/content.css?v=$VERSION';
//--></script>
<link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/editor.css?v=$VERSION" />
<link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/datepicker.css?v=$VERSION" />
<link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/override.datepicker.css?v=$VERSION" />
<script type="text/javascript" src="$URL_CONTENT/tinymce/tinymce.min.js?v=$VERSION"></script>
<script type="text/javascript" src="$URL_CONTENT/js/datepicker.js?v=$VERSION"></script>
<script type="text/javascript" src="$URL_CONTENT/js/tinymce.init.js?v=$VERSION"></script>
<script type="text/javascript" src="$URL_CONTENT/js/datepicker.init.js?v=$VERSION"></script>
__HTML__
}

sub html_admin_menu
{
  our ($CGI_SIGNIN,$ICON_LOGOUT,$ICON_NEW,$ICON_DOCS);
  print qq(<noscript><p class="no-script">ブラウザのスクリプトサポートを有効化してください。</p></noscript>\n) if($DELETE_KEY);
  print <<__HTML__;
<ul class="commands">
  <li><a href="$CGI_SIGNIN?dir=$DIR&mode=logout">$ICON_LOGOUT</a></li>
  <li><a href="$CGI_SELF?mode=post&ac=show&dir=$DIR">$ICON_NEW</a></li>
  <li id="docs"><a href="$URL_CONTENT/docs.pdf" target="_blank">$ICON_DOCS</a></li>
</ul>
__HTML__
}

sub html_confirm
{
  our ($ICON_YES,$ICON_CANCEL);
  my ($index,$yes,$cancel,$message) = @_;
  my ($t_yes,$t_no) = (text('yes'),text('no'));
  print qq(<noscript><p class="no-script">ブラウザのスクリプトサポートを有効化してください。</p></noscript>\n) if($DELETE_KEY);
  print <<__HTML__;
<div class="text-center">
  <p>$message</p>
  <p>
    <a href="$yes" class="btn btn-success">$t_yes</a>
    <a href="$cancel" class="btn btn-danger">$t_no</a>
  </p>
</div>
__HTML__
}

sub html_admin_comments
{
  print qq(<p class="notice">※背景色などはこの画面では反映されません。各記事の確認ボタンでプレビュー表\示してください。</p>\n);
}


#管理画面の記事修正表示
sub form_modify
{
  my $index = shift || return;
  my $token = generate_token();

  my $items = ref $index eq 'HASH' ? $index : parse(LOG()->{$index});
  my $images = $items->{images};
  my $files = $items->{files};
  my $token_param = $token ? "&ct=$token" : '';
  my $index_param = $index ? "#article-$index" : '';
  my $page = session_value('page');
  my $page_param = $page ? "&page=$page" : '';

  my %b_checked;
  my %n_selected;
  my %o_checked;
  my %d_checked;

  my @options = getOptionColumns();

  my $directlink = stdio::urldecode_($items->{direct});
  my $public = $items->{public};
  my $pub_checked = $public == 0 ? ' checked' : '';
  $n_selected{$items->{notify}} = ' selected';

  if($directlink)
    {
      $d_checked{directlink} = ' checked';
    }
  else
    {
      $d_checked{disabled} = ' disabled';
    }

  my ($cy,$cm,$cd) = (localtime)[5,4,3];

  $cy += 1900;
  $cm += 1;

  my $notify_to = $items->{period};

  my $tags = @TAG > 0 ? join(',',@TAG) : text('disabled');

  my $delete_tag;

  my $np_str = text('no settings');
  my $np_period = '';

  my ($attacheddir,$attachedvdir) = get_attached_info($public);
  my $attached_ords = $items->{attached_ords};

  $o_checked{'outline'} = $items->{outline} ? ' checked' : "";
  $o_checked{'headline'} = $items->{headline} ? ' checked' : "";

  my @aimages = map { $_ ? (-e "$attacheddir/s/$_" ? "$attachedvdir/s/$_" : "$attachedvdir/$_") : "$IMG_CGI/click-to-select.svg"; } @$images;
  my @span_notices = map { $_ ? qq(<span class="notice">画像を変更したい場合は画像をクリックしてファイルを選択してください。</span>) : ''; } @$images;

  my $content_margin = $IMAGE_WIDTH + 32;
  my @n_options = map { qq(<option value="$_"$n_selected{$_}>$NOTIFICATION[$_]</option>); } 0 .. $#NOTIFICATION;

  if($notify_to > 0)
    {
      my @ntime = localtime($notify_to);
      ($cy,$cm,$cd) = (1900 + $ntime[5],1 + $ntime[4],$ntime[3]);

      $np_str = "${cy}年${cm}月${cd}日まで";
      $np_period = "$cy/$cm/$cd";
    }

  my $category = $items->{category};
  my @cats = grep { ($category & $CATEGORIES{$_}{flag}) == $CATEGORIES{$_}{flag}; } keys %CATEGORIES;
  my %cats = map { $_ => 1 } @cats;
  my @category_selections = map {
    sprintf q(<label for="category-%1$s"><input type="checkbox" id="category-%1$s" name="category" value="%1$s"%2$s />%3$s</label>),$_->{value},exists $cats{$_->{value}} ? 'checked' : '',$CATEGORIES{$_->{value}}{label};
  } @CATEGORIES;

  my $reserve = $items->{reserve} || '';

  print <<__HTML__;
<form method="post" action="$CGI_SELF" enctype="multipart/form-data">
  <input type="hidden" name="mode" value="modify" /><input type="hidden" name="ac" value="post" />
  <input type="hidden" name="dir" value="$DIR" /><input type="hidden" name="index" value="$index" />
  <input type="hidden" name="token" value="$token" />

  <div class="article-editor">
    <div class="head">

      <div class="column nowrap">
        タイトル：
        <input type="text" name="title" value="$items->{title}" class="text subject" />
        $DATE_TITLE
        <input type="text" name="date" value="$items->{date}" class="text date">
      </div>

      <div class="column attrs">
        <!-- 見出し表示
          <input type="checkbox" id="chkb_ol" name="outline" value="1"$o_checked{'outline'}><label for="chkb_ol">OUTLINE</label>&nbsp;&nbsp;&nbsp; -->
          <input type="checkbox" id="chkb_hl" name="headline" value="1"$o_checked{'headline'}><label for="chkb_hl">トップページに表示する</label>
          &nbsp;&nbsp;
          <input type="checkbox"  value="1" id="chkb_resv" name="public"$pub_checked><label for="chkb_resv">非表示(保留)設定にする。</label>
          &nbsp;&nbsp;
          通知表示
          <select name="notification" class="text">@n_options</select>&nbsp;&nbsp;
          通知期間
          <input type="text" value="$np_str" id="np-1" readonly class="text date">
          <a href="#" id="submit-clear-date">$ICON_CLEARDATE</a>
          <input type="hidden" name="notify_period" value="$np_period" id="np-0">
      </div>

      <!-- category selections -->
      <div class="column attrs">
        @category_selections
      </div>

      <div class="column nowrap" id="column-direct">
        <input type="checkbox" name="article-is-directlink" value="1" id="is-direct-link"$d_checked{directlink} /><label for="is-direct-link" title="URLを設定して見出しのみに表示します。">直リンク設定にする</label>
          <input type="text" name="direct" value="$directlink" id="direct-link" class="text subject" placeholder="http://"$d_checked{disabled} />
      </div>

    </div><!-- end of .head -->

    <div class="body">
      <div class="column editor-body clearfix">
        <div class="editor-image">
          <ul>
__HTML__
    for(0 .. $#$images)
      {
        print <<__HTML_IN__;
            <li>
              <span class="image-wrap">
                <img id="upload-image-$_" class="upload-image" src="$aimages[$_]" data-empty-image="$IMG_CGI/no-image.svg" />
                <input type="file" id="image-$_" class="image" name="image_$_" accept="image/jpeg,image/png,image/gif" />
              </span>
              $span_notices[$_]
              <span class="delete-image"><input type="checkbox" name="delete-image_$_" value="1" id="delete-image-$_" /><label for="delete-image-$_">画像を削除する</label></span>
            </li>
__HTML_IN__
      }

    print <<__HTML__;
          </ul>
        </div>
        <div class="editor-content" style="margin-left: ${content_margin}px">

        <!-- オプション・添付ファイル -->
        <table width="100%">
__HTML__

  #削除キー
  print qq(<tr><th>削除キー</th><td><input type="text" name="dkey" maxlenght="8" placeholder="*******" size="12">　<span class="notice">※変更する場合のみ</span></td></tr>\n) if($DELETE_KEY);

  print qq(<!--ここからオプション -->\n);
  for(0 .. $#options)
    {
      print qq(<!-- $_ -->\n);
      print qq(<tr valign="middle">\n);
      print qq(<th>【$options[$_]】</td>\n);
      print qq(<td><input type="text" name="option_$_" value="$items->{options}->[$_]" class="text full"></td>\n);
      print qq(</tr>);
    }
  print qq(<!--ここまでオプション -->\n);

  print qq(<!--ここから添付ファイル -->\n);
  print <<__HTML__;
             <tr valign="top">
               <th class="attached">【添付ファイル】</th>
               <td>
                 <p><a id="submit-add-new" href="$CGI_FMANAGER?ac=upload&dir=$DIR&key=$items->{key}">$ICON_ADD</a></p>
                 <div id="gkdfjgd89576984" class="files">
__HTML__

  if(@$attached_ords)
    {
      #ここから添付ファイル列挙
      print qq(<ul class="attached-files editor">\n);
      foreach(@$attached_ords)
        {
          my $size_str = "ファイルサイズ:" . getFilesizeString("$attacheddir/$_");
          print qq(<li><a target="_blank" href="$attachedvdir/$_" class="file" title="$size_str">$items->{attached}{$_}</a></li>);
        }
      print qq(\n</ul>\n);
    }
  else
    {
      print qq(<p>アップロードした添付ファイルはありません。</p>\n);
    }

  #ここまで
  print <<__HTML__;
                 </div>
                 <div class="file-manager">
                   <input id="ac_ren" type="radio" name="fman_action"><label for="ac_ren"><span id="ch" style="color:gray;">ファイル名変更</span></label>&nbsp;&nbsp;&nbsp;
                   <input id="ac_rm" type="radio" name="fman_action"><label for="ac_rm"><span id="rm" style="color:gray;">ファイル削除</span></label>&nbsp;&nbsp;
                   <a href="$CGI_FMANAGER?dir=$DIR&key=$items->{key}" id="submit-file-manager">$ICON_FMANAGER</a>
                 </div>
               </td>
             </tr>
           </table>
           <textarea name="body">$items->{body}</textarea>
        </div><!-- end of .editor-content-->
      </div><!--end of .column.editor-body.clearfix -->

    </div><!-- end of .body -->

    <div class="foot">
      <div class="column commands">
        <p>
          <a href="javascript:;" id="submit-article-modify">$ICON_SUBMIT_MODIFY</a>
          <a href="$CGI_SELF?mode=cancel&dir=$DIR$token_param$page_param$index_param" class="submit-cancel"><span>$ICON_BACK</span></a>
        </p>
      </div>
    </div>
  </div>
</form>
__HTML__

  1;
}

#管理画面の新規投稿
sub form_post
{
  our $MAX_UPLOAD_SIZE;
  my $token = generate_token();
  my $hform = FORM();

  my $token_param = $token ? "&ct=$token" : '';
  my $page = session_value('page');
  my $page_param = $page ? "&page=$page" : '';

  my @ctime = localtime;
  my ($cy,$cm,$cd) = (localtime)[5,4,3];

  $cy += 1900;
  $cm += 1;

  #ここまで

  my $tags = @TAG > 0 ? join(',',@TAG) : '使用できません';
  my $input_attached_file;
  my $num_input_attached = ($hform->{'at'} && $hform->{'at'} =~ /^([0-9]*)$/) ? int $hform->{'at'} : 1;

  my @options = getOptionColumns();
  my $date = pl_strftime('%Y/%m/%d');

  my @n_options = map { qq(<option value="$_">$NOTIFICATION[$_]</option>) } 0 .. $#NOTIFICATION;

  my $content_margin = $IMAGE_WIDTH + 30;
  my @category_selections = map {
      sprintf q(<label for="category-%1$s"><input type="checkbox" id="category-%1$s" name="category" value="%1$s" />%2$s</label>),$_->{value},$CATEGORIES{$_->{value}}{label};
  } @CATEGORIES;

  my $reserve = '';

  print <<__HTML__;
<form method="post" action="$CGI_SELF" enctype="multipart/form-data">
  <input type="hidden" name="mode" value="post">
  <input type="hidden" name="ac" value="post">
  <input type="hidden" name="dir" value="$DIR">
  <input type="hidden" name="at" value="$num_input_attached">
  <input type="hidden" name="token" value="$token">

  <div class="article-editor">
    <div class="head">
      <div class="column nowrap">
        タイトル：
        <input type="text" name="title" class="text subject">
        $DATE_TITLE
        <input type="text" name="date" value="$date" class="text date">

        <div class="inner-right">
          投稿位置
          <select name="locate" class="text">
            <option value="0" selected>通常</option>
            <option value="1">最後</option>
          </select>
        </div>
      </div>

      <div class="column attrs">
        <!-- 見出し表示
          <input type="checkbox" id="chkb_ol" name="outline" value="1" checked><label for="chkb_ol">OUTLINE</label>&nbsp;&nbsp;&nbsp; -->
        <input type="checkbox" id="chkb_hl" name="headline" value="1" checked><label for="chkb_hl">トップページに表示する</label>
        &nbsp;&nbsp;
        <input type="checkbox"  value="1" id="chkb_resv" name="public" class="text"><label for="chkb_resv">非表示(保留)設定にする。</label>
        &nbsp;&nbsp;

        通知表示
        <select name="notification" class="text">@n_options</select>&nbsp;
        通知期間 <input type="text" value="設定なし" id="np-1" readonly class="text date">
        <a href="#" id="submit-clear-date">$ICON_CLEARDATE</a>
        <input type="hidden" name="notify_period" value="0/0/0" id="np-0">
      </div>

      <!-- category selections -->
      <div class="column attrs">
        @category_selections
      </div>

      <div class="column nowrap" id="column-direct">
        <input type="checkbox" name="article-is-directlink" value="1" id="is-direct-link" /><label for="is-direct-link" title="URLを設定して見出しのみに表示します。">直リンク設定にする</label>
          <input type="text" name="direct" id="direct-link" class="text subject" disabled placeholder="http://" value="" />
      </div>
    </div>

    <div class="body">
      <div class="column editor-body clearfix">
        <div class="editor-image">
          <ul>
__HTML__
  for( 0 .. $NUM_OF_IMAGES - 1 )
    {
      print <<__HTML_IN__;
            <li>
              <span class="image-wrap">
                <img id="upload-image-$_" class="upload-image" src="$IMG_CGI/click-to-select.svg" alt="ここに画像を登録できます">
                <input type="file" id="image-$_" class="image" name="image_$_" accept="image/jpeg,image/png,image/gif" />
              </span>
            </li>
__HTML_IN__
    }
  print <<__HTML__;
          </ul>
        </div>
        <div class="editor-content" style="margin-left: ${content_margin}px">
          <table width="100%">
__HTML__

  #削除キー
  print qq(<tr><th>削除キー(必須)</th><td><input type="text" name="dkey" maxlenght="8" size="12"></td></tr>\n) if($DELETE_KEY);

  print qq(<!--ここからオプション -->\n);
  for(0 .. $#options)
    {
      print qq(<!-- $_ -->\n);
      print qq(<tr valign="middle">\n);
      print qq(<th>【$options[$_]】</td>\n);
      print qq(<td><input type="text" size="50" name="option_$_" class="text"></td>\n);
      print qq(</tr>\n);
    }
  print qq(<!--ここまでオプション -->\n);

  no warnings qw/once/;
  my $max_upload = int($MAX_UPLOAD_SIZE / 1024 / 1024);

  for(my $i=0;$i<$num_input_attached;$i++)
    {
      print qq(<tr valign="top">\n);

      print qq(<th>\n);
      if($i==0)
        {
          print qq(<a id="submit-increse-upload" href="javascript:;">$ICON_INCRESE_UPLOAD</a>\n);
          print qq(<br><span class="message">一度にアップロードできる<br>合計最大サイズは${max_upload}MBです。</span>\n);
        }
      print qq(</th>\n);

      print qq(<td>\n);
      print qq(  <input type="file" name="file_$i" class="file" style="margin-bottom:5px;"><br>\n);
      print qq(  表示名 <input type="text" name="file_name_$i" class="text filename"><br>\n);
      print qq(  保存ファイル名を<input type="radio" id="myfilename-system-$i" name="myfilename_$i" value="1" checked onclick="showbox($i,false);"><label for="myfilename-system-$i">システムに任せる(推奨)</label>\n);
      print qq(  <input type="radio" id="myfilename-own-$i" name="myfilename_$i" value="2" onclick="showbox($i,true);"><label for="myfilename-own-$i">指定する</label>\n);
      print qq(  <div id="inputbox_$i"></div>\n);
      print qq(</td>\n);

      print qq(</tr>\n);
    }
  print <<__HTML__;
          </table>
          <textarea name="body"></textarea>
        </div><!-- end of .editor-content -->
      </div><!-- end of .column.editor-body.clearfix -->

      </div><!-- end of .body -->
      <div class="foot">
        <div class="column commands">
          <p>
            <a href="javascript:;" id="submit-article-post">$ICON_SUBMIT_POST</a>
            <a href="$CGI_SELF?mode=cancel&dir=$DIR$token_param$page_param" class="submit-cancel"><span>$ICON_BACK</span></a>
          </p>
        </div>
      </div>
    </div>
  </form>
__HTML__
  1;
}

#既存記事をテンプレートして新規作成する場合にロードさせる。
sub html_script_article
{
  use JSON;

  my $index = shift || return;
  my $datafile = "$DIR_DATA/$FDIR/$LOG_NAME";
  my $hlog = LOG();

  cgiOut(text('can not open file')) unless(getLogEx($datafile,0,0,$index));
  return unless(exists $hlog->{$index});

  my $row = parse($hlog->{$index});
  my $json_str = JSON->new->encode($row);

  print <<__SCRIPT__;
<script type="text/javascript"><!--
var POSTDATA = $json_str;
//--></script>
<script type="text/javascript" src="$URL_CONTENT/js/post.init.js?v=$VERSION"></script>
__SCRIPT__

  1;
}


#各記事の削除キーをクッキーに記録させるスクリプト
sub html_dkey_script
{
  my $str = shift;

  print <<__SCRIPT__;
<script type="text/javascript" src="$URL_CONTENT/js/deletekey.js?v=$VERSION"></script>
<script type="text/javascript"><!--

function do_auth(action,dir,index)
{
  var oWin = window.open("","_blank","width=300,height=200 menubar=no,scrollbars=no,toobar=no");
  var oDoc = oWin.document;

  oDoc.writeln('<html>');
  oDoc.writeln('<head>');
  oDoc.writeln('<meta http-equiv="Content-Type" value="text/html; charset=UTF-8">');
  oDoc.writeln('<title>削除キーの入力</title>');

  oDoc.writeln('</head>');
  oDoc.writeln('<body onload="document.getElementById(\\"pwd\\").focus();" style="background:white url($IMG_CGI/bg_auth.jpg) no-repeat center center;">');
  oDoc.writeln('<table width="100%" height="100%"><tr><td align="center" valign="middle">');
  oDoc.writeln('<div style="color:red;margin:1em;">$str</div>');
  oDoc.writeln('<div style="font-size:12pt;padding:1em;margin:1em;border-bottom:1px #aaaaaa dashed;">削除キーを入力してください</div>');

  oDoc.writeln('<form method="post" action="$CGI_SELF">');
  oDoc.writeln('<input id="pwd" type="password" name="dkey" style="font-size:86.5%">');
  oDoc.writeln('<input type="submit" value="confirm">');
  oDoc.writeln('<input type="hidden" name="mode" value="dk">');
  oDoc.writeln('<input type="hidden" name="dir" value="' + dir  + '">');
  oDoc.writeln('<input type="hidden" name="index" value="' + index + '">');
  oDoc.writeln('<input type="hidden" name="md" value="' + action + '">');
  oDoc.writeln('</form>');
  oDoc.writeln('</td></tr></table>');
  oDoc.writeln('</body></html>');

  oDoc.close();
}

//--></script>
__SCRIPT__
}

sub html_manager_script
{
  print <<__SCRIPT__;
<script type="text/javascript">
<!--
var CGI = '$CGI_FMANAGER';
//--></script>
<script type="text/javascript" src="$URL_CONTENT/js/editor.modify.js?v=$VERSION"></script>
__SCRIPT__
}

sub html_form_process_script
{
  print <<__SCRIPT__;
<script type="text/javascript" src="$URL_CONTENT/js/editor.js?v=$VERSION"></script>
<script type="text/javascript" src="$URL_CONTENT/js/fmanage.upload.js?v=$VERSION"></script>
<script type="text/javascript" src="$URL_CONTENT/js/jquery.simplePopup.pack.js?v=$VERSION"></script>
__SCRIPT__

}

#管理画面記事ヘッダ部分のチェックボックス-ボタン制御
sub html_admin_enumeration_script
{
  print <<__SCRIPT__;
<script type="text/javascript" src="$URL_CONTENT/js/admin.js?v=$VERSION"></script>
__SCRIPT__

}


#管理画面ヘッダータイトル
sub html_header_title
{
  my $str = shift;
  print qq(<div class="editor-header">\n);
  print qq(<h1><span>$str</span></h1>\n);
  print qq(</div>\n);
}


sub tagOut
{
  my ($tag,$inner,%attrs) = @_;
  my @keys = keys %attrs;
  my @attrs = map { s/\"/\\\"/g; qq($_="$attrs{$_}") } @keys if(@keys);

  return length $inner ? sprintf('<%1$s%2$s>%3$s</%1$s>',$tag,' ' . join(' ',@attrs),$inner) : '';
}

#管理画面の各記事
sub table_admin_article
{
  our $CGI_USER;
  my ($rownum,$index,$rheaders,$n) = @_;
  $n = 0 unless(defined $n);
  my $r = parse(LOG()->{$index});
  my @oheaders = getOptionColumnsFromHeader($rheaders);

  my $public_write = $r->{public} == 0 ? text('this item is protected') : '';
  my $ctime = time;

  my %selected = ($r->{notify},'selected');
  my $images = $r->{images};
  my $options = $r->{options};
  my $attached_ords = $r->{attached_ords};
  my $attached = $r->{attached};

  my $created = getstrftime($r->{registdate});
  my $lastupdate = $r->{lastupdate} ? getstrftime($r->{lastupdate}) : '';

  my %checked = ('public' => $r->{public} == 0 ? " checked" : "",
                 'outline' => $r->{outline} == 1 ? " checked" : "",
                 'headline' => $r->{headline} == 1 ? " checked" : "");

  #編集モード表示
  my $article_width = $ARTICLE_WIDTH;
  my $article_align = '';
  my $article_style = '';
  my $article_body_color = 'white';

  #ここまで
  my ($attacheddir,$attachedvdir) = get_attached_info($r->{public});

  #通知アイコンの表示
  my $notify_icon = (($r->{notify_to} && $r->{notify_to} > $ctime && $r->{notify}) || (!$r->{notify_to} && $r->{notify})) ? $NOTIFICATION_DISP[$r->{notify}] : '';

  #カテゴリ表示
  my $category = $r->{category};
  my @categories = map { $_->{tag} } grep { ($category & $_->{flag}) == $_->{flag} } @CATEGORIES;

  print <<__HTML__;
<div class="container admin-article" id="article-$index">
  <div class="row row-date">
    <div class="col-12">
      @{[tagOut('time',$created,'class' => 'created'),tagOut('time',$lastupdate,'class' => 'updated')]}
    </div>
  </div>

  <!-- #ここからヘッダー -->
  <div class="row row-head">
    <div class="container">
      <div class="row">
        <div class="col-md-10 article-subject">
          $notify_icon
          @categories
          <span class="subject-text">$r->{title}</span>
        </div>
        <div class="col-md-2 article-date">$DATE_TITLE  $r->{date}</div>
      </div>
      <div class="row">
__HTML__

  if(!$DELETE_KEY && ($n != 1))
    {
      print <<__HTML__;
      <div class="col-10">
        <form action="$CGI_SELF" class="form-inline" style="margin:0;padding:0;">
          <input type="hidden" name="dir" value="$FDIR" />
          <input type="hidden" name="mode" value="displaycheck" />
          <input type="hidden" name="index" value="$index" />
          <!--input type="checkbox" id="chkb_ol_$index" onclick="notifyCheckBoxClick(this,'sbmt_$index','$index');" name="outline" value="1"$checked{'outline'} /><label for="chkb_ol_$index">OUTLINE</label>&nbsp;&nbsp;-->
          <div class="form-check">
            <input type="checkbox" class="form-check-input" id="chkb_hl_$index" onclick="notifyCheckBoxClick(this,'sbmt_$index','$index');" name="headline" value="1"$checked{'headline'} />
            <label for="chkb_hl_$index">トップページに\表\示する</label>
          </div>
          <div class="form-check mx-3">
            <input type="checkbox" class="form-check-input" id="chkb_pub_$index" onclick="notifyCheckBoxClick(this,'sbmt_$index','$index');" name="public" value="1"$checked{'public'} />
            <label for="chkb_pub_$index">掲載を保留する</label>
          </div>
          <input type="submit" id="sbmt_$index" class="btn btn-primary btn-sm" value="設定変更" disabled />
        </form>
      </div>
__HTML__

    }

  if($n != 1)
    {
      print qq(<div class="col-2 ml-auto command-order">\n);
      if($rownum < $#{LOG(1)})
        {
          print qq(<a href="$CGI_SELF?mode=order&ord=220&dir=$DIR&index=$index" title="この記事を最後に">$ICON_ORDER_BOTTOM</a>\n);
          print qq(<a href="$CGI_SELF?mode=order&ord=22&dir=$DIR&index=$index" title="この記事を一つ下に">$ICON_ORDER_DOWN</a>\n);
        }
      if($rownum)
        {
          print qq(<a href="$CGI_SELF?mode=order&ord=11&dir=$DIR&index=$index" title="この記事を一つ上に">$ICON_ORDER_UP</a>\n);
          print qq(<a href="$CGI_SELF?mode=order&ord=110&dir=$DIR&index=$index" title="この記事を最初に">$ICON_ORDER_TOP</a>\n);
        }
      print qq(</div>\n);
    }

  print <<__HTML__;
      </div><!-- end .row -->
    </div><!-- end .container -->
  </div><!-- end .row.row-head -->

__HTML__

  print qq(<div class="row protected"><div class="col-12">$public_write</div></div>) if($public_write);
  print qq(<div class="row row-content">);

  my $directlink = stdio::urldecode_($r->{direct});
  if($directlink)
    {
      print qq(<div class="col direct-link">\n);
      print qq(この記事は直リンク設定です。<br><a href="$directlink" target="_blank">$directlink</a>\n);
      print qq(</div>\n);
    }
  else
    {
      print qq(<div class="col-3">\n);
      print qq(<ul class="image-container">\n);
      for(0 .. $NUM_OF_IMAGES - 1)
        {
          print qq(<li>\n);
          my $image = $images->[$_];
          if($image)
            {
              my $image_uri = "$attachedvdir/$image";
              my $thumb_uri = -e "$attacheddir/s/$image" ? "$attachedvdir/s/$image" : $image_uri;
              print $IMAGE_LINK ? qq(<a href="$image_uri" class="article-image" rel="lightbox" title="$r->{title}"><img border="0" src="$thumb_uri" alt=""></a>\n)
                                : qq(<img src="$image_uri" border="0">);
            }
          else
            {
              print qq(<img border="0" src="$IMG_CGI/no-image.svg" alt="NO IMAGE">\n);
            }
          print qq(</li>\n);
        }
      print qq(</ul>\n);
      print qq(</div>\n);
      print qq(<div class="col-9">\n);

      #ここから記事データ出力

      #ここからオプション

      print qq(<div class="container">\n);
      if(first { length $_ > 0 } @{$options})
        {
          print qq(<dl class="row article-data">\n);
          for(0 .. $#oheaders)
            {
              if(defined $options->[$_] && length $options->[$_])
                {
                  stdio::setLink(\$options->[$_],'target="_blank"');
                  print qq(  <dt class="col-3 py-2">【$oheaders[$_]】</dt>\n);
                  print qq(  <dd class="col-9 py-2">$options->[$_]</dd>\n);
                }
            }
          print qq(</dl>\n);
        }

      #ここから添付ファイル
      if(@$attached_ords > 0)
        {
          print qq(<dl class="row article-data">\n);
          print qq(  <dt class="col-3 py-2">【添付ファイル】</dt>\n);
          print qq(  <dd class="col-9 py-2">\n);
          print qq(    <div class="files">\n);
          print qq(      <ul class="attached-files">\n);
          foreach(@$attached_ords)
            {
              my $size_str = "ファイルサイズ:" . getFilesizeString("$attacheddir/$_");
              print qq(          <li><a target="_blank" href="$attachedvdir/$_" title="$size_str">$attached->{$_}</a></li>);
            }
          print qq(\n    </ul>\n);
          print qq(    </div>\n);
          print qq(  </dd>\n);
          print qq(</dl>\n);
        }

      #本文
      print qq(<div class="row"),@$options > 0 || @$attached_ords > 0 ? '' : qq( style="border: none;"),'>';
      print qq(<div class="col-12 articleWrap">\n$r->{body}\n</div>\n);
      print qq(</div>\n);

      print qq(</div><!-- end of .container -->\n);
      print qq(</div><!-- end of .col -->\n);
    }
  print qq(</div><!-- end of .row.row-content -->\n);

  if($n != 1)
    {
      my $has_files = ($images || @$attached_ords > 0) ? ' has-files' : '';
      print qq(<div class="row row-foot">\n);
      print qq(  <div class="col-12">\n);
      print qq(    <a href="$CGI_SELF?mode=remove&ac=show&dir=$DIR&index=$index" class="submit-remove">$ICON_REMOVE</a>\n);
      print qq(    　<a href="$CGI_SELF?mode=clone&ac=show&dir=$DIR&index=$index" class="submit-clone$has_files" title="$TITLE_CLONE_DESC">$ICON_COPY</a> \n);
      print qq(    <a href="$CGI_SELF?mode=post&ac=show&dir=$DIR&index=$index" class="submit-add-copy" title="$TITLE_ADD_COPY">$ICON_ADD_COPY</a> \n);
      print qq(    <a href="$CGI_SELF?mode=modify&ac=show&dir=$DIR&index=$index" class="submit-modify">$ICON_MODIFY</a>  \n);
      print qq(    　<a target="_blank" href="$CGI_USER?dir=$DIR&article=$index" title="$CGI_USER?dir=$DIR&article=$index" class="submit-view">$ICON_ARTICLE</a>\n) unless($directlink);
      print qq(  </div><!-- end of .col-12 -->\n);
      print qq(</div><!-- end of .row.row-foot -->\n);
    }
  print qq(</div><!-- end of .container -->\n);
}

sub get_admin_list_templates
{
  split /\<!-- split --\>/, <<__HTML__;
<div class="container">
  <div class="table-responsive">
    <table class="table table-striped admin-article-list">
      <thead class="bg-dark">
        <tr>
          <th>&nbsp;</th>
          <th>@{[text('Date')]}</th>
          <th width="60%">@{[text('Title')]}</th>
          <th>@{[text('Commands')]}</th>
          <th>@{[text('Change Order')]}</th>
        </tr>
      </thead>
      <tbody>

<!-- split --> 

      </tbody>
    </table>
  </div>
</div>
<script type="text/javascript"><!--
(function(\$) {
  \$(window).on('load',function() { \$('span.unknown-title').css('opacity',1); });
})(jQuery);
//--></script>
__HTML__
}

sub table_admin_list
{
  our $CGI_USER;
  my ($rownum,$index) = @_;
  my $r = parse(LOG()->{$index});

  my @row_classes = ();
  push @row_classes,'protected' if($r->{public} == 0);
  push @row_classes,'no-headline' if($r->{headline} == 0);
  my $row_class = @row_classes ? sprintf(' class="%s"',join(' ',@row_classes)) : '';
  my $protected = $r->{public} == 0 ? sprintf('<span class="badge badge-danger">%s</span>',text('protected')) : '&nbsp;';

  my $ctime = time;

  # my $created = getstrftime($r->{registdate});
  # my $lastupdate = $r->{lastupdate} ? getstrftime($r->{lastupdate}) : '';
  my $directlink = stdio::urldecode_($r->{direct});

  #通知アイコンの表示
  my $notify_icon = (($r->{notify_to} && $r->{notify_to} > $ctime && $r->{notify}) || (!$r->{notify_to} && $r->{notify})) ? $NOTIFICATION_DISP[$r->{notify}] : '';

  #カテゴリ表示
  my $category = $r->{category};
  my @categories = map { $_->{tag} } grep { ($category & $_->{flag}) == $_->{flag} } @CATEGORIES;
  my @orders = ();
  if($rownum < $#{LOG(1)})
  {
    push @orders,qq(<a href="$CGI_SELF?mode=order&ord=220&dir=$DIR&index=$index" title="この記事を最後に">$ICON_ORDER_BOTTOM</a>\n);
    push @orders,qq(<a href="$CGI_SELF?mode=order&ord=22&dir=$DIR&index=$index" title="この記事を一つ下に">$ICON_ORDER_DOWN</a>\n);
  }
  if($rownum)
  {
    push @orders,qq(<a href="$CGI_SELF?mode=order&ord=11&dir=$DIR&index=$index" title="この記事を一つ上に">$ICON_ORDER_UP</a>\n);
    push @orders,qq(<a href="$CGI_SELF?mode=order&ord=110&dir=$DIR&index=$index" title="この記事を最初に">$ICON_ORDER_TOP</a>\n);
  }
  my @commands = ();
  push @commands,qq(<select class="form-control form-control-sm" onchange="return do_select_action.apply(this);">\n);
  push @commands,qq(<option>@{[ text('Select Action') ]}</option>\n);
  push @commands,qq(<option value="$CGI_SELF?mode=remove&ac=show&dir=$DIR&index=$index">@{[ text('Remove') ]}</option>\n);
  push @commands,qq(<option value="$CGI_SELF?mode=clone&ac=show&dir=$DIR&index=$index" data-handler="submitClone">@{[ text('Copy') ]}</option> \n);
  push @commands,qq(<option value="$CGI_SELF?mode=post&ac=show&dir=$DIR&index=$index">@{[ text('Create From') ]}</option> \n);
  if($r->{public})
    {
      push @commands,qq(<option value="$CGI_USER?mode=&ac=&dir=$DIR&article=$index">@{[ text('protected') ]}</option>\n);
    }
  else
    {
      push @commands,qq(<option value="$CGI_USER?mode=&ac=&dir=$DIR&article=$index">@{[ text('public') ]}</option>\n);
    }
  push @commands,qq(<option value="$CGI_USER?dir=$DIR&article=$index" data-window="_blank">@{[ text('Show') ]}</option>\n) unless($directlink);
  push @commands,qq(<option value="$directlink" data-window="_blank">@{[ text('Direct Link') ]}</option>\n) if($directlink);
  push @commands,qq(</select>\n);
  my $cat_notify = '';
  $cat_notify = sprintf('<span class="cat-notify-wrap">%s&nbsp;%s</span>',join('&nbsp;',@categories),$notify_icon) if(@categories || $notify_icon);
  my $title = $r->{title} || sprintf '<span class="unknown-title">%s</span>',text('Unknown title');

  print <<__HTML__;
    <tr$row_class id="article-$index">
      <td class="article-public">$protected</td>
      <td class="article-date"> $r->{date} </td>
      <td class="article-title">$cat_notify <a href="$CGI_SELF?mode=modify&ac=show&dir=$DIR&index=$index">$title</a> </td>
      <td class="article-commands"> @commands </td>
      <td class="article-orders"> @orders </td>
    </tr>
__HTML__
}

1;
