#!/usr/bin/perl
use strict;
use warnings;

=pod

 記事一つの描画の描画を定義しています。
 各データディレクトリ内のproperty.plにtable_article関数が定義されていない場合はこの関数がコールされます。

 独自のレンダリングを行いたい場合は、このsub render{} 関数を元にproperty.plへtable_article関数を定義してください。

  <div class="container bbs">
    <p><span class="login">【ログイン中】</span></p>

    <div class="container article" id="article-xxxxxxxxx">
      <div class="row">
        <span class="col-auto">通知</span>
        <span class="col-auto">タイトル</span>
        <time class="col-auto ml-auto">サブタイトル</time>
      </div>

      <div class="row">
        <div class="col">
          本文
        </div>
      </div>
      <ul class="images row justify-content-center pl-0">
        <li class="col-6 col-md-3 px-1 my-1">画像</li>
        ...
      </ul>
      <ul class="attaches row">
        <li class="col-2">添付ファイルのリンク</li>
        ...
      </ul>
    </div>
  </div>
=cut

no strict qw/refs/;

*table_article = *render unless *table_article{CODE};
*html_start = *defStart unless *html_start{CODE};
*html_end = *defEnd unless *html_end{CODE};

sub defStart
{
  our ($DIR,$DIR_CONTENT,$URL_CONTENT,$DIR_PASSWORD);
  our ($HTML_TITLE);

  my ($str) = @_;
  my $isLoginStr = &validate_session($DIR_PASSWORD) ? '<span class="badge badge-primary badge-login">【管理者】</span>' : '';
  my $adminScript = <<'__JSCRIPT__';
<script type="text/javascript"><!--
(function($)
 {
   $(function()
     {
       $('.article.protected').on('click','a',function(ev) { ev.preventDefault(); }).find('*').css('cursor','default');
     });
 })(jQuery);

//--></script>
__JSCRIPT__

  my $datastyle = -e "$DIR_CONTENT/data/$DIR/style.css" ? qq(<link rel="stylesheet" type="text/css" href="$URL_CONTENT/data/$DIR/style.css") : '';
  my $datascript = -e "$DIR_CONTENT/data/$DIR/include.js" ? qq(<script type="text/javascript" src="$URL_CONTENT/data/$DIR/include.js"></script>) : '';

  print <<EOI;
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="description" content="" />
    <meta name="keywords" content="" />
    <meta name="robots" content="noindex,nofollow" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="format-detection" content="telephone=no" />

    <title>$HTML_TITLE</title>

    <!-- style sheet -->
    <link rel="stylesheet" type="text/css" href="$URL_CONTENT/style.css" />
    <link rel="stylesheet" type="text/css" href="$URL_CONTENT/bootstrap/css/bootstrap.min.css" />
    <link rel="stylesheet" type="text/css" href="$URL_CONTENT/lightbox2/css/lightbox.css" />
    <style type="text/css"><!--

      
    --></style>

    $datastyle

    <!-- script code -->
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>

    $adminScript

    $datascript
  </head>
  <body>
    <noscript>
      <div class="alert alert-danger">ご使用中のブラウザはスクリプトの実行が無効になっています。正常に表示できない場合がございますが、予めご了承ください。</div>
    </noscript>
    <div class="container my-3">

      <!--ヘッダー-->
      <header>
        <nav class="navbar navbar-expand-sm fixed-top navbar-light bg-light border-bottom">
          <a class="navbar-brand" href="javascript:;"><span>$HTML_TITLE</span></a><small class="mx-3">$isLoginStr</small>
        </nav>
      </header>

      <!--メインコンテンツ-->
      <div class="container-fluid px-0 pt-5">
        <div class="row">
          <div class="col">

            
EOI
}

sub defEnd
{
  our $URL_CONTENT;
  print <<EOI;
          </div><!-- .col -->
        </div><!-- .row -->
      </div><!-- .container-fluid -->

      <!--フッター-->
      <footer>
        <div class="inner">
        </div>
      </footer>

    </div><!-- .container -->
    <script type="text/javascript" src="$URL_CONTENT/lightbox2/js/lightbox.min.js"></script>
  </body>
</html>
EOI
}

sub render
{
  our (@TAG,$DATE_TITLE,@NOTIFICATION_DISP,$PROTECTED,$IMAGE_LINK);
  my ($index,$rheaders) = @_;
  my $hlog = LOG();
  my $r = parse($hlog->{$index});
  my $ctime = time;
  my ($attacheddir,$attachedvdir) = get_attached_info($r->{public});

  #unhtmlentities
  foreach my $tag (@TAG)
    {
      $r->{body} =~ s/&lt;${tag}\s*([^&]*)&gt;/<$tag\ $1>/ig;
      $r->{body} =~ s/&lt;\/$tag&gt;/<\/$tag>/ig;
    }

  my $notify_html = '';
  $notify_html = qq(<span class="col-auto pr-0">$NOTIFICATION_DISP[$r->{notify}]</span>) if(($r->{notify_to} && $r->{notify_to} > $ctime && $r->{notify}) || (!$r->{notify_to} && $r->{notify}));

  my $protected = $r->{public} ? '' : qq(<div class="col-auto px-1"><span class="badge badge-danger">$PROTECTED</span></div>);
  my $classProtected = $r->{public} ? '' : ' protected';

  #ここから記事テーブル出力開始
  print qq(\n);

  #ここからヘッダーカラム
  print <<__HTML__;
<div class="container-fluid article${classProtected}" id="article-$index">
  <div class="row align-items-center">
    $notify_html
    $protected
    <time class="col-auto">$DATE_TITLE $r->{date}</time>
  </div>
  <div class="row align-items-center py-3 border mx-0 article-header">
    <div class="col">
      <h1 class="h4 mb-0 title" title="$r->{title}">$r->{title}</h1>
    </div>
  </div>
__HTML__

  my $lf = "\n";
  my $images = $r->{images};

  print q(<div class="article-body row border-left border-right border-bottom text-justify mt-0">),$lf;
  print q(  <div class="col-12 pt-3">),$lf;
  print qq(    $r->{body}),$lf;
  print q(  </div>),$lf;

  #画像
  if(@$images)
  {
    print qq(<div class="col-12 pt-3">),$lf;
    print qq(<ul class="article-images row justify-content-center pl-0 mx-3">\n);
    foreach(@$images)
    {
      next unless $_;
      my $image_uri = "$attachedvdir/$_";
      my $thumb_uri = -e "$attacheddir/s/$_" ? "$attachedvdir/s/$_" : $image_uri;
      print qq(<li class="col-12 col-md-auto px-1 my-1">); 
      if($IMAGE_LINK)
      {
        print qq(<a href="$image_uri" data-lightbox="$_"><img src="$thumb_uri" alt="*" title="クリックで画像が拡大できます" /></a>\n);
      }
      else
      {
        print qq(<img src="$thumb_uri" style="display:block;" width="100%" />);
      }
      print qq(</li>),$lf;
    }
    print qq(</ul>),$lf;
    print q(</div>),$lf;
  }

  print q(</div>),$lf; #end of artcile-body

  #ここからオプション
  my $options = $r->{options};
  my $oheaders = getOptionColumnsFromHeader($rheaders);
  if(first { length $_ > 0 } @$options)
  {
    print qq(<div class="article-options">\n);
    for(0 .. $#$oheaders)
    {
      if(defined $options->[$_] && length $options->[$_] > 0)
      {
        print qq(<dl class="row">\n);
        stdio::setLink(\$options->[$_],qq(target="_blank"));
        print qq(<dt class="col">$oheaders->[$_]</dt>\n);
        print qq(<dd class="col">$options->[$_]</dd>\n);
        print qq(</dl>\n);
      }
    }
    print qq(</div>\n);
  }

  #ここから添付ファイル
  my $attached = $r->{attached_ords};
  if(@$attached > 0)
    {
      print qq(<ul class="row align-items-center position-relative article-attaches" style="list-style: none;">\n);
      foreach(@$attached)
        {
          my $size_str = "ファイルサイズ:" . getFilesizeString("$attacheddir/$_");
          my $name_str = $r->{attached}->{$_};
          my $ext = m/(\.\w+)$/ || '';
          my $download = m/\.pdf$/i ? '' : sprintf(' download="%s%s"',$r->{attached}->{$_},$ext);
          print qq(<li class="col-auto p-0 m-1"><a class="badge badge-success" target="_blank" href="$attachedvdir/$_" title="$name_str／$size_str"$download>$name_str</a></li>\n);
        }
      print qq(</ul>\n);
    }

  #記事枠ここまで
  print q(</div><!-- end of .article -->);

  1;
}

1;

