/*******************************************************************************

  削除キー 対応

*******************************************************************************/
(function($)
 {
   $('.submit-modify,.submit-remove,.submit-clone')
     .click(function(ev)
            {
              ev.preventDefault();
              alert('削除キーが必要です。');
            });

 })(jQuery);
