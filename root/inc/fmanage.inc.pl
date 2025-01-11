#!/usr/bin/perl
use strict;
use warnings;

our ($DIR,$L_KEY,$URL_CONTENT,$VERSION,$IMAGE_WIDTH);
our ($CGI_FMANAGE,$CGI_FMANAGER);
our ($ICON_PROCESS_DONE,$ICON_WINDOW_CLOSE,$ICON_INCRESE_UPLOAD,$ICON_SUBMIT_UPLOAD);

###########################
# アップロード表示
###########################
sub table_upload
{
  my $r = shift;
  my $key = $r->{key};
  my $hform = FORM();
  my $num_input_attached = $hform->{'at'} && $hform->{'at'} =~ /^([0-9]*)$/ ? (0 + $hform->{'at'}) :  3;
  my $max_upload = int($stdio::max_byte / 1024 / 1024);
  my $i = 0;

  print <<__HTML__;
<noscript><strong style="color:red;">ブラウザのスクリプト機能を有効にしてください</strong></noscript><br>
<table class="fmanage" cellspacing="1">
  <thead><tr><th>ファイルのアップロード</th></tr></thead>
  <tbody>
    <tr>
      <td>
        <form action="$CGI_FMANAGER" method="post" enctype="multipart/form-data">
          <input type="hidden" name="mode" value="run">
          <input type="hidden" name="ac" value="upload">
          <input type="hidden" name="dir" value="$DIR">
          <input type="hidden" name="key" value="$key">
          <input type="hidden" name="at" value="$num_input_attached">
  
          <table>
            <caption><span class="message">一度にアップロードできる合計最大サイズは${max_upload}MBです。</span></caption>
            <tr>
              <th><a id="submit-increse-upload" href="javascript:;">$ICON_INCRESE_UPLOAD</a></th>
              <td>
                <input type="file" name="file_0" class="file" style="margin-bottom:5px;"><br>
                表示名 <input type="text" name="file_name_0" class="text filename"><br>
                ファイル名を<input type="radio" name="myfilename_0" value="1" checked onclick="showbox(0,false);">システムに任せる(推奨)&nbsp;&nbsp;
                <input type="radio" name="myfilename_0" value="2" onclick="showbox(0,true);">指定する
                <div id="inputbox_$i"></div>
              </td>
            </tr>
          </table>
          <p class="commands"><a id="submit-upload" href="javascript:;" title="アップロード">$ICON_SUBMIT_UPLOAD</a></p>
          <div style="font-size:80%;color:green;margin-top:1em;">&nbsp;</div>
        </form>
      </td>
    </tr>
  </tbody>
</table>
<p class="commands"><a href="javascript:closeWindow();">$ICON_WINDOW_CLOSE</a></p>
<script type="text/javascript" src="$URL_CONTENT/js/fmanage.upload.js?v=$VERSION"></script>
__HTML__

  if($num_input_attached > 1)
    {
      print <<__HTML__;
<script type="text/javascript"><!--
  increse_upload_area($num_input_attached);
//--></script>
__HTML__
    }
}


###########################
# リネーム表示
###########################
sub table_rename
{
  my $r = shift;
  my $key = $r->{key};
  my @items = @{$r->{items}};
  my @image = @{$r->{images}};
  my %files = %{$r->{attached}};
  my @attached_ords = @{$r->{attached_ords}};
  my $caption = FORM()->{success} ? '<caption><span>更新しました。</span></caption>' : '';

  print <<__HTML__;
<table class="fmanage" cellspacing="1">
  $caption
  <thead>
    <tr>
      <th>ファイル名の編集</th>
    </tr>
  </thead>
  <tbody>
__HTML__

  foreach(@attached_ords)
    {
      next if(length $_ <= 0);

      print <<__HTML__;
    <tr>
      <td bgcolor="white" nowrap>
        <form name="$key" action="$CGI_FMANAGER" method="post">
          <input type="hidden" name="dir" value="$DIR">
          <input type="hidden" name="mode" value="run">
          <input type="hidden" name="ac" value="rename">
          <input type="hidden" name="key" value="$items[$L_KEY]">
          <input type="hidden" name="file" value="$_">
          <input type="hidden" name="desc" value="$files{$_}">
          ファイル名 <input type="text" name="ren" value="$_" class="filename">&nbsp;&nbsp;
          表\示名 <input type="text" name="chg" value="$files{$_}" class="filename">&nbsp;&nbsp;
          <input type="submit" value="修正を実行する">
        </form>
      </td>
    </tr>
__HTML__
    }

  print <<__HTML__;
  </tbody>
</table>
<p class="commands"><span class="notice">※注意:ファイル名に日本語は使えません。半角英数字、ハイフン、アンダーバー、ピリオドのみ使用できます。</span></p>
<p class="commands"><a href="$CGI_FMANAGER?dir=$DIR&ac=done&key=$key">$ICON_PROCESS_DONE</a></p>
__HTML__

  1;
}

###########################
# 削除表示
###########################
sub table_remove
{
  my $r = shift;
  my $key = $r->{key};
  my @items = @{$r->{items}};
  my @image = @{$r->{images}};
  my %files = %{$r->{attached}};
  my @attached_ords = @{$r->{attached_ords}};


  print qq(<table class="fmanage" cellspacing="1">\n);
  print qq(<thead><tr><th colspan="3">添付ファイルの削除</th></tr></thead>\n);
  print qq(<tbody>\n);
  foreach(@attached_ords)
    {
      if(length $_ <= 0)
        {
          next;
        }
      print qq(<tr>\n);
      
      print qq(<td nowrap>ファイル名 <span class="filename">$_</span></td>\n);
      print qq(<td nowrap>表示名 <span class="filename">$files{$_}</span></td>\n);
      print qq(<td nowrap>\n);
      print qq(<form name="$key" action="$CGI_FMANAGER" method="post">\n);
      print qq(<input type="hidden" name="dir" value="$DIR">\n);
      print qq(<input type="hidden" name="mode" value="run">\n);
      print qq(<input type="hidden" name="ac" value="remove">\n);
      print qq(<input type="hidden" name="key" value="$items[$L_KEY]">\n);
      print qq(<input type="hidden" name="file" value="$_">\n);
      print qq(<input type="submit" value="削除する" style="border:1px solid gray;background-color:#eeeeee;">\n);
      print qq(</form>\n);
      print qq(</td>\n);
      print qq(</tr>\n);
    }
  print qq(</tbody>\n);
  print qq(</table></div>\n);
  print qq(<div align="center"><a href="$CGI_FMANAGER?dir=$DIR&ac=done&key=$key">$ICON_PROCESS_DONE</a></div>\n); 
}


###########################
# リネーム表示
###########################
sub table_done
{
  my $r = shift;
  my @items = @{$r->{items}};
  my @image = @{$r->{images}};
  my %files = %{$r->{attached}};
  my @attached_ords = @{$r->{attached_ords}};
  my $public = $r->{public};

  my ($attacheddir,$attachedvdir) = get_attached_info($public);

  print qq(<table class="fmanage" cellspacing="1">\n);
  print qq(<thead><tr><th>処理が終了しました。</th></tr></thead>\n);
  print qq(<tbody>\n);
  print qq(<tr><td bgcolor="white">\n);
  print qq(<p align="center">▼現在の添付ファイルの状況▼</p>\n);
  print qq(<div id="fshd9a8yf65476f" class="files">\n);
  if(@attached_ords > 0)
    {
      print qq(<ul class="attached-files editor">\n);
      foreach(@attached_ords)
        {
          my $size_str = "ファイルサイズ:" . &getFilesizeString("$attacheddir/$_");
          print qq(<li><a target="_blank" href="$attachedvdir/$_" title="$size_str">$files{$_}</a></li>);
        }
      print qq(\n</ul>\n);
    }
  else
    {
      print qq(<p align="cener">アップロードされた添付ファイルはありません。</p>\n);
    }
  print qq(</div>\n);  
  print qq(</td></tr>);
  print qq(</tbody>\n);
  print qq(</table>\n);
  print qq(<p class="commands"><a href="javascript:closeUploadWindow();">$ICON_WINDOW_CLOSE</a></p>\n);
}

###########################
# htmlヘッダー
###########################
sub fmanage_start
{
  my ($str) = @_;

  print <<__HTML__;
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>$str</title>
  <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
  <script type="text/javascript" src="$URL_CONTENT/js/fmanage.js?v=$VERSION"></script>

  <link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/fmanage.css?v=$VERSION" />
  <link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/button.css?v=$VERSION" />
  <style type="text/css"><!--
    input[type=file][name=image] { width: ${IMAGE_WIDTH}px; }
  //--></style>
</head>
<body>
__HTML__
}

###########################
# htmlフッター
###########################
sub fmanage_end
{
  print <<__HTML__;
</body>
</html>
__HTML__
}

1;
