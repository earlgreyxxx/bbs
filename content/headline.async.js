/*******************************************************************************

  ヘッドライン・ロード

*******************************************************************************/
(function($,j,s)
 {
   var $topics = $(s).empty();

   $.getJSON(j)
     .done(function(json)
           {
             var url = json.cgi + '?dir=' + json.dir;
             $.each(json.rows,
                    function()
                    {
                      var $li = $('<li />').appendTo($topics);
                      $('<span />')
                        .addClass('info-date')
                          .html(this.date)
                            .appendTo($li);

                      $('<a />')
                        .addClass('info-title')
                          .prop('href',this.direct ? this.direct : (url + '&article=' + this.key))
                            .html(this.title)
                              .appendTo($li);

                      if(this.notify)
                        $(this.notify).appendTo($li);
                    });
           })
       .fail(function()
             {
               $topics.append('<li>お知らせの読み込みに失敗しました。時間をおいてもう一度アクセスしてください。</li>');
             });
 })(jQuery,URI_JSON,SELECTOR);

