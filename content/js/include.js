/*******************************************************************************

  管理画面に挿入されるスクリプト

*******************************************************************************/
var submitClone = function(ev)
{
  var params = '';
  if(ev)
    {
      ev.preventDefault();

      if(jQuery(this).hasClass('has-files') && window.confirm("コピーされた記事はデフォルトで保留設定になります。\n\nファイルもコピーしますか？\nファイルをコピーしたくない場合は「キャンセル」を選択してください。"))
        params = '&copyfile=1';
    }
  else
    {
      if(window.confirm("コピーされた記事はデフォルトで保留設定になります。\n\nファイルもコピーしますか？\nファイルをコピーしたくない場合は「キャンセル」を選択してください。"))
        params = '&copyfile=1';
    }
  location.href = this.href + params;
};

(function($)
 {
   $('.submit-clone').click(submitClone);

   window.is_smt = 0;
   var location_hash = '';
   var do_scroll = function(s,v)
     {
       return function() {
         var paddingTop = parseInt($(document.body).css('padding-top').replace(/px$/,''));
         var pos = s && $(s).length > 0 ? ($(s).offset().top - paddingTop) : 0;
         if(window.hasOwnProperty('is_smt') && window.is_smt > 0 && pos > window.is_smt)
           pos -= window.is_smt;

         return $('html,body').animate({scrollTop: pos }, v, 'swing').promise();
       };
     };


   $("a[href*='#']")
     .each(function()
           {
             var pos;
             var href = location.href;
             if((pos = href.indexOf('#')) > 0)
               href = href.substr(0,pos);

             if(href.length > 0)
               $(this).attr('href',$(this).attr('href').replace(href,''));
           });

   if(location.hash.match(/^(#.+)/))
     {
       location_hash = RegExp.$1;
       history.replaceState(null,null,location.pathname+location.search);
       $(do_scroll(location_hash,300));
     }

 })(jQuery);

