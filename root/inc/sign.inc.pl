#
# ログイン用のHTML出力
#
sub html_login
{
  my ($r_options,$str,$title) = @_;
  my $done = $FORM{done};
  my $alert = '';

  $done =~ s/&amp;/&/g;
  $title = '<h2 class="h6">パスワードを入力してください。</h2>' unless $title;
  $alert = qq(<div class="position-relative" style="height: 2em;margin-top: -2em;"><p class="py-2 alert alert-danger fade show small position-absolute w-100" role="alert">$str</p></div>) if($str);

  print <<__HTML__;
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <title>記事編集モードへはログインが必要です</title>

    <!-- Bootstrap core CSS -->
    <link href="$URL_CONTENT/bootstrap/css/bootstrap.min.css" rel="stylesheet">

    <!-- Custom styles for this template -->
    <link rel="stylesheet" type="text/css" href="$URL_CONTENT/css/sign.css?v=$VERSION" />
  </head>

  <body class="text-center" onload="document.getElementById('phrase').focus();">
    <form class="form-signin" name="form1" method="post" action="$CGI_SIGNIN">
      <input type="hidden" name="mode" value="verify">
      <input type="hidden" name="done" value="$done">

      <h1 class="h4 mb-5">記事管理</h1>
      $alert
      <div class="form-group">
        @{[join("\n",@$r_options)]}
      </div>

      <div class="form-group">
        $title
        <p>
          <input class="form-control text-center" type="password" name="phrase" id="phrase">
        </p>
      </div>

      <div class="input-group">
        <button class="btn btn-lg btn-primary btn-block" type="submit">送信</button>
        <p class="mt-5 mb-3 text-muted text-left message">※ブラウザのクッキーを使用します。ブラウザのクッキー機能を無効にしている場合は利用できません。</p>
      </div>
    </form>
    <script src="$URL_CONTENT/js/jquery-3.3.1.min.js"></script>
    <script src="$URL_CONTENT/js/popper.min.js"></script>
    <script src="$URL_CONTENT/bootstrap/js/bootstrap.min.js"></script>
    <script type="text/javascript"><!--
      (function(\$) {
        if(\$('.alert:visible').length > 0)
          window.setTimeout(function(){ \$('.alert:visible').css('opacity',0); },3000);
      })(jQuery);
    //--></script>
  </body>
</html>
__HTML__
}

1;
