/*******************************************************************************

	ファイル管理ウィンドウのスクリプト

*******************************************************************************/
function showbox(i,b)
{
  var obj = document.getElementById('inputbox_' + i);
  var str = 'ファイル名 <input type="text" class="text filename" name="system_file_name_' + i + '" ><br>';
      str += '<span style="font-size:80%;color:blue;">※拡張子は自動的に付きますので入力しないでください<br>※半角英数文字、ハイフン、アンダーバーのみ使用できます。</span>';

  obj.innerHTML = b ? str : '';
}

var increse_upload_area = null;


(function()
 {
   $(function()
     {
       if(window.FileReader)
         {
           /*----------------------------------------------------------------------
           添付ファイル選択
           ----------------------------------------------------------------------*/
           $(document)
             .on('change',
                 'input.file',
                 function(ev)
                 {
                   if(this.files.length == 1)
                     {
                       var re = new RegExp('\\.[^\.]+$');
                       $(this)
                         .siblings('input.filename')
                           .val(this.files[0].name.replace(re,''));
                     }
                 });
         }

         /*-------------------------------------------------------------------------
           ファイルアップロード数の onchangeハンドラ
         -------------------------------------------------------------------------*/
       var count = 1;
       var numtr = 0;
       var $at = $('input:hidden[name="at"]');
       $('#submit-increse-upload')
         .click(function(ev)
                 {
                   ev.preventDefault();

                   var $a = $(this);
                   var $table = $a.parents('table:first');
                   var $tr = $('<tr />').css('vertical-align','top').appendTo($table);

                   var $th = $('<th />').appendTo($tr);
                   $('<a />')
                     .attr('href','javascript:;')
                       .html('<span class="button button-decrese">削除</span>')
                         .appendTo($th)
                           .click(function(ev)
                                  {
                                    ev.preventDefault();
                                    $(this).parents('tr:first').remove();

                                    if(--numtr == 0)
                                      {
                                        count = 1;
                                        $at.val(count);
                                      }
                                  });

                   var $td = $('<td/>').appendTo($tr);
                   var htmltext = [
                     '<input type="file" name="file_' + count + '" class="file" style="margin-bottom:5px;"><br>',
                     '表示名 <input type="text" name="file_name_' + count + '" class="text filename"><br>',
                     '保存ファイル名を<input type="radio" id="myfilename-system-' + count + '" name="myfilename_' + count + '" value="1" checked onclick="showbox(' + count + ',false);"><label for="myfilename-system-' + count + '">システムに任せる(推奨)</label>',
                     '<input type="radio" id="myfilename-own-' + count + '" name="myfilename_' + count + '" value="2" onclick="showbox(' + count + ',true);"><label for="myfilename-own-' + count + '">指定する</label>'];

                   $td.html(htmltext);

                   $('<div />').attr('id','inputbox_' + count).appendTo($td);

                   numtr++;
                   count++;

                   $at.val(count);
                 });
     });

   increse_upload_area = function(num)
     {
       $(function()
         {
           while(num-- > 0)
             $('#submit-increse-upload').click();
         });
     }
 })(jQuery);


