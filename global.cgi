#!/usr/bin/perl
use strict;
use warnings;
use lib qw!./root/inc!;

use File::Basename;
use IO::File;
use Text::Path;

=com
 keys %urlpath  =>  (hostname
                     request_vdir
                     script_name
                     extension
                     cginame
                     script_filedir
                     script_filename
                     script_extension
                     isrewrite)
=cut
our %urlpath = urlpath();

# debugOut(\%urlpath);

my $urldir = $urlpath{hostname}.$urlpath{request_vdir};
my $ext = $urlpath{extension};

our $CGINAME = $urlpath{cginame};

#caller self
our $CGI_SELF = $urlpath{hostname} . $urlpath{script_name};

#administration
our $CGI_ADMIN    = "$urldir/admin$ext";
our $CGI_FMANAGER = "$urldir/fmanage$ext";
our $CGI_SIGNIN   = "$urldir/sign$ext";

#public
our $CGI_USER = "$urldir/update$ext";
our $CGI_FEED = "$urldir/feed$ext";

=com
------------------------------------------------------------------------------
 * general settings
------------------------------------------------------------------------------
=cut
# base directory
our $DIR_BASE = dirname(__FILE__);

# modify if rewrite module enabled.
our $REQUEST_BASE = $DIR_BASE;

# base url
our $URL_BASE = $urlpath{request_vdir};

# data top directory
our $DIR_DATA = $DIR_BASE . '/data';

# virtual directory of $DIR_DATA for http access(included in URL)
our $VDIR_DATA = "$urlpath{request_vdir}/data";

# temporary working directory ( no require slash suffix )
our $DIR_TEMPORARY = $DIR_BASE . '/tempo';

# root URI for HTML contents.
our $URL_CONTENT = realpath($urlpath{request_vdir}."/content");

# root directory for static contents
our $DIR_CONTENT = dirname(__FILE__).'/content';

# virtual directory path to images for using CGI.
our $IMG_CGI = "$URL_CONTENT/images/cgi";

# a directory name of saved and loaded attached files.
our $ATTACHED_NAME = 'attached';

# default data directory name when nothing specified.
our $DIR_DEFAULT = 'template';

# data log file name.
our $LOG_NAME = 'log.dat.cgi';

# num of attaching images.
our $NUM_OF_IMAGES = 1;

# limit uploading size.(unit: byte)
our $MAX_UPLOAD_SIZE = 10 * 1024 * 1024;

# images has (or not) http link?
our $IMAGE_LINK = 1;

# email address of Administrator.
our $ADMIN_MAIL = 'temp@temp.jp';

# delete key for Administrator.
our $DELETE_PHRASE = 'adminpassword';

# pagination of Administrator's view
our $ADMIN_NAVI_PREV = '前のページ';
our $ADMIN_NAVI_NEXT = '次のページ';

# interval time for cleaning garbage in temporary directory
our $TTL = 3 * 60;

# cookie life time (default is 30days)
our $COOKIE_LIFETIME = 3600 * 24 * 30;

# define session parameters.
our %SESSION_PARAMS = (scriptname    => $CGI_SELF,
                       sign          => $CGI_SIGNIN,
                       expire        => 3600,
                       cookie_expire => 86400 * 60,
                       sessiondir    => $DIR_TEMPORARY . '/session');

# define strings of icon settings. ( with '<select>' tag )
#   recording order is 0,1,2,3,....
#   ordering direction is ASC.
my @NOTIFICATIONS =
(
  'なし'     => '',
  '新着情報' => qq(<span class="badge badge-primary">NEW</span>),
  'トピック' => qq(<span class="badge badge-warning">TOPICS</span>),
  '注目'     => qq(<span class="badge badge-success">LOOK</span>)
);

our @NOTIFICATION = do {
  my $num = scalar(@NOTIFICATIONS) / 2 - 1;
  @NOTIFICATIONS[ map { $_ * 2 } (0 .. $num) ];
};
# setting display above.
our @NOTIFICATION_DISP = do {
  my %NOTIFICATIONS = @NOTIFICATIONS;
  @NOTIFICATIONS{ @NOTIFICATION };
};

# orders of data directory with 'signin page'.
# if you define this settings, must fill all data directories.
# if no need ordering, bellow array must be empty.
our @ORDER_DIR = ();

# button(icons) HTML tag settings.
our $ICON_ADD = qq(<span class="button button-add">新規追加</span>);
our $ICON_ADD_COPY = qq(<span class="btn btn-primary button-add-copy">この記事を元に作成</span>);
our $ICON_ARTICLE = qq(<span class="btn btn-info button-confirm">表示を確認する</span>);
our $ICON_BACK = qq(<span class="button button-back">前に戻る</span>);
our $ICON_CANCEL = qq(<span class="button button-cancel">キャンセル</span>);
our $ICON_CLEARDATE = qq(<span class="button button-clear-date">クリア</span>);
our $ICON_COPY = qq(<span class="btn btn-warning button-clone">記事を複成</span>);
our $ICON_DOCS = qq(<span class="button-docs font-awesome">操作説明書</span>);
our $ICON_FMANAGER = qq(<span class="button button-fmanager">添付ファイルの管理</span>);
our $ICON_INCRESE_UPLOAD = qq(<span class="button button-increse">アップロード枠を増やす</span>);
our $ICON_LOGOUT = qq(<span class="button-logout font-awesome">ログアウト</span>);
our $ICON_MODIFY = qq(<span class="btn btn-success button-modify">記事を修正</span>);
our $ICON_NEW = qq(<span class="button-add-new font-awesome">新規投稿する</span>);
our $ICON_ORDER_BOTTOM = qq(<span class="button button-bottom">最下段へ</span>);
our $ICON_ORDER_DOWN = qq(<span class="button button-down">下へ</span>);
our $ICON_ORDER_TOP = qq(<span class="button button-top">最上段へ</span>);
our $ICON_ORDER_UP = qq(<span class="button button-up">上へ</span>);
our $ICON_PROCESS_DONE = qq(<span class="button button-process-done">終了します</span>);
our $ICON_REMOVE = qq(<span class="btn btn-danger button-remove">記事を削除</span>);
our $ICON_SUBMIT_MODIFY = qq(<span class="button button-submit-modify">修正する</span>);
our $ICON_SUBMIT_POST = qq(<span class="button button-submit-post">登録する</span>);
our $ICON_SUBMIT_UPLOAD = qq(<span class="button button-submit-upload font-awesome">アップロード</span>);
our $ICON_YES = qq(<span class="btn btn-primary button-yes">はい</span>);
our $ICON_WINDOW_CLOSE = qq(<span class="button button-close-window">ウィンドウを閉じる</span>);
our $TITLE_CLONE_DESC = 'デフォルトで保留設定になります';
our $TITLE_ADD_COPY = '画像と添付ファイルは引き継げません';

=com
------------------------------------------------------------------------------
  define error or message text.
------------------------------------------------------------------------------
=cut
our %TEXT_ja = (
  'can not open file' => 'ファイルが開けません',
  'failed to close file' => 'ファイルのクローズに失敗しました',
  'something error occured' => 'なんらかのエラーが発生しました',
  'can not write file' => 'ファイルの書込みに失敗しました',
  'data directory is not exists' => 'データディレクトリがありません',
  'data directory is empty' => 'データがありません',
  'not implement yet' => 'まだ実装されていません',
  'process is busy state' => '時間をおいてお試しください',
  'invalid arguments were given' => '引数指定が無効です',
  'specified index value is unavailable' => '無効なインデックスが指定されました。',
  'there is no index' => 'インデックスの指定がありません',
  'require delete key' => '削除キーは必ず入力してください。',
  'attached file key not found' => 'キーがありません',
  'input was empty' => '入力が空です。',
  'use only alphabet,number,under bar,hyphen,period' => '半角英数、アンダーバー、ハイフン、ピリオド以外の文字は使えません',
  'invalid process' => '不正な方法でアクセスが行われました',

  'delete key authentication was faied' => '削除キーの認証に失敗しました。',
  'click here and go back' => 'ここをクリックしてお戻りください。',
  'password does not match' => 'パスワード・フレーズが一致しません。',
  'input password for "%s"' => '「%s」のパスワードを入力してください。',
  'input password for' => 'のパスワードを入力してください。',
  'require re-authentication' => '再認証が必要です。',
  'session was timeout or authentication error has occured' => 'セッションがタイムアウトしているか認証エラーが発生しています。',
  'invalid cgi access' => '不適切なCGI呼び出しです',
  'file name was already used' => 'ファイル名は既に使用されています',
  'remove article, ok?' => 'この記事を削除します。よろしいですか？',

  'Create Article' => '新規記事登録',
  'Modify Article' => '記事修正',
  'Remove attached files' => '添付ファイルの削除',
  'Rename attached files' => '添付ファイル名の変更',
  'Upload attached files' => '添付ファイルのアップロード',
  'Upload image files' => '画像のアップロード',
  'Process was done' => '処理終了',

  #メインメニュー
  'Select data directory' => 'データを選択してください。',
  'Show by'  => '表示形式',
  'By list'      => 'リスト',
  'By article'   => '詳細',

  'this item is protected' => '※ この記事は保留設定です。一般公開はされていません',
  'Other directories' => '他のデータへ',

  #記事管理リスト表示
  'Date'         => '日付',
  'Title'        => 'タイトル',
  'Commands'     => '操作',
  'Change Order' => '表示順',

  #コマンド
  'Select Action' => '選択してください',
  'Remove'        => '削除',
  'Copy'          => 'コピー',
  'Create From'   => '作成',
  'Show'          => '表示確認',
  'Direct Link'   => 'リンク先にジャンプ',
  'public'        => '公開',

  'Unknown title' => 'タイトル未入力',
  'disabled'      => '使用できません',
  'no settings'   => '設定なし',

  'protected'     => '保留',
);

=com
------------------------------------------------------------------------------
 $debug : Debug option...
   show detail => 1
   hide detail => 0
------------------------------------------------------------------------------
=cut
our $debug_mode = 0;

=com
 bellows are compatibility use.
=cut
our $HEADER_STRING = "";
our $FOOTER_STRING = "";

=com
------------------------------------------------------------------------------
 変数定義(オプション)
------------------------------------------------------------------------------
=cut
our $VERSION = do {
  my $v = '';
  if(-e 'VERSION' && (my $in = IO::File->new('VERSION')))
    {
      $v = $in->getline;
      chomp $v;
      $in->close;
    }
  $v;
};

# no using this variable
our $ServerType = 1;

# split raw data
our $split = '<>';
our $split2 = '/';

# log definition
our ($L_KEY,$L_TITLE,$L_DATE,$L_BODY,$L_ATTR,$L_FILE,$L_DELETE,$L_OPTION_START) = (0 .. 7);

# table of convertions.
our %CONVERT_TABLE = ( 'amp'  => '&',
                       'quot' => '"',
                       'lt'   => '<',
                       'gt'   => '>' );

# method of using cryption and private key.
our $CIPHER = 'Blowfish_PP';
our $SECRET_KEY = 'fkDdSSij30o4af5kJds5lfjsd38oo27';

# graphic library module for using. ( only 'GD' or 'Image::Magick' )
our $IMAGELIB = 'GD';

# LOG FORMAT TYPE (Log::Split or Log::Dumper or ...)
# override in propterty.pl of each data directory.
our $LOGTYPE = 'Log::Dumper';

# pagination delta
our $PAGE_DELTA = 4;

1;
