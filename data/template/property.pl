#データタイプ
our $DATA_TYPE = 'orig';
our $NUM_OF_IMAGES;
our $LOGTYPE = 'Log::Dumper';

#リンクするディレクトリ名
#データタイプがORIGの場合はコメントアウト
#$LINK_TO = '';

#個々のディレクトリ設定

our $HTML_TITLE = 'タイトル';
our $FEED_DESCRIPTION = 'ここに更新情報の説明を記述する。';
our $FEED_AUTHOR = 'ここに著作者';

#削除キー機能の有無
our $DELETE_KEY = 0;

#表示画像幅(ピクセル)
our $IMAGE_WIDTH = 200;

#1ページに表示する記事数
our $PAGE_MAX = 10;

#ヘッドラインに表示する件数
our $HEADLINE_LIMIT = 3;

#必ず変更してください。
our $DIR_PASSWORD = 'password';

#必ず変更してください。ディレクトリ名と同じ名前にしてください。
#***重要****
#データタイプが LINKの場合、リンク元と同じにしなければなりません。
our $LOCK_NAME = './lock/template';

#必ず変更してください。ディレクトリ名と同じ名前が無難です。
our $COOKIE_NAME = "template";

#記事囲みの幅指定
our $ARTICLE_WIDTH = "750px";

#ヘッダー位置の2番目のタイトル。表示しないなら空にする。
our $DATE_TITLE = "";

#画像にリンクを張る。
our $IMAGE_LINK = 1;

###HTML
#ページ移動のアイコン表示。画像を付ける場合は<img>タグで記述。
our $NAVI_PREV = '<span>前のページへ</span>';
our $NAVI_NEXT = '<span>次のページへ</span>';
our $NAVI_ALL = '<span>すべて表示する</span>';

#ページ送りの代わりにページネーションを使う
#our $NAVI_IS_PAGINATION = 1;

#オプション(添付ファイルを保存ディレクトリ)
#特に指定が無ければ空にしておく。
our $DIR_ATTACHED = '';

#オプション(添付ファイルの保存仮想ディレクトリ)
#特に指定が無ければ空にしておく。
our $VDIR_ATTACHED = '';

#保留時のファイル移動先ディレクトリ名
our $DIR_PROTECTED_NAME = "bc183024d3b0332c207e2d7a26894a74";

#
our $PROTECTED = '<span class="protected">保留</span>';

#カテゴリ定義
our @CATEGORIES = ( { name => 'カテゴリ1',tag => '<span class="badge badge-info">カテゴリ1</span>',label => 'カテゴリ1',value => 'cat-1',flag => 2**0},
                    { name => 'カテゴリ2',tag => '<span class="badge badge-info">カテゴリ2</span>',label => 'カテゴリ2',value => 'cat-2',flag => 2**1},
                    { name => 'カテゴリ3',tag => '<span class="badge badge-info">カテゴリ3</span>',label => 'カテゴリ3',value => 'cat-3',flag => 2**2},
                  );

#gets.cgi で取得するキー名のデフォルト値
our $DEFAULT_GET_KEYS = 'dnlt';

#使用しない変数
our @TAG = ('b','font','a');
our $ARTICLE_ALIGN = "center";
#our $ARTICLE_STYLE = "border:0px solid #CCCCCC\; margin:0 auto\;";
our $ARTICLE_HEADER_TEXTCOLOR = '#333';
our $ARTICLE_HEADER_COLOR = '#FFF';
our $ARTICLE_BODY_TEXTCOLOR = '#333';
our $ARTICLE_BODY_COLOR = '#FFF';
#ここまで変数

# 画像ファイル数上書き
$NUM_OF_IMAGES = 3;

1;
