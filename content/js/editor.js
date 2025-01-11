/*******************************************************************************
  エディターに挿入されるスクリプト
******************************************************************************/
(function($)
 {
   $(function()
     {
       /*-------------------------------------------------------------------------
         publish submit form.
       -------------------------------------------------------------------------*/
       $('#submit-article-modify,#submit-article-post')
         .click(function(ev)
                {
                  ev.preventDefault();
                  ev.stopPropagation();

                  $(this)
                    .parents('form')
                      .submit();
                })
           .parents('form')
             .keypress(function(ev)
                       {
                         if(ev.which == 13)
                           {
                             console.log('リターンキーが押されました。処理を停止します。');
                             ev.preventDefault();
                           }
                       });

       if(window.hasOwnProperty('FileReader'))
         {
           /*----------------------------------------------------------------------
            画像選択時の画像プレビュー表示
           ----------------------------------------------------------------------*/
           $('img.upload-image').each(function() { var $image = $(this); $image.data('orig',$image.attr('src')); });

           $('.delete-image > input[type=checkbox]')
             .on('click',
                 function(ev)
                 {
                   var id_num = this.id.split('-').pop();
                   var $image = $('#upload-image-' + id_num);
                   var $file = $('#image-' + id_num);
                   if(this.checked)
                     {
                       $image.attr('src',$image.data('empty-image'));
                       if($file.prop('files').length > 0)
                         $file.val('');
                     }
                   else
                     {
                       $image.attr('src',$image.data('orig'));
                     }
                 });

           $('.image')
             .on('change',
                 function()
                 {
                   var id_num = this.id.split('-').pop();
                   var $image = $('#upload-image-' + id_num);
                   if(!this.files.length)
                     {
                       if($image.data('orig') != $image.attr('src'))
                         $image.attr('src',$image.data('orig'));
                       return;
                     }

                   var file = this.files[0];
                   if(file.type.match('^image/'))
                     {
                       var reader = new FileReader();
                       reader.onload = function() {
                           $image.attr('src',this.result);
                       };
                       reader.readAsDataURL(file);
                     }
                 });

           $('.editor-image > ul > li')
             .on('drop',
                 function(ev)
                 {
                   ev.preventDefault();
                   ev.stopPropagation();
                   var dropnum = ev.originalEvent.dataTransfer.files.length;
                   var $file = $(this).find('.image');

                   if(dropnum != 1 || $file.size() != 1)
                     return;

                   try
                     {
                       $file.prop('files',ev.originalEvent.dataTransfer.files);
                     }
                   catch(e)
                     {
                       console.log(e);
                     }

                   $file.on('change');
                 })
               .on('dragover dragenter dragleave',
                   function(ev)
                   {
                     ev.preventDefault();
                     ev.stopPropagation();
                   });
         } //if(window.FileReader)

       /*----------------------------------------------------------------------
        直リンクチェックボックス切替
       ----------------------------------------------------------------------*/
       var $chk = $('#is-direct-link');
       $chk.click(function()
                  {
                    if(this.checked)
                      {
                        $('#direct-link').removeAttr('disabled');
                        $('.article-editor > .body').height(0);
                        $('#column-direct').css({backgroundColor:'white'});
                      }
                    else
                      {
                        $('#direct-link').attr('disabled','disabled');
                        $('.article-editor > .body').css({height : 'auto'});
                        $('#column-direct').css({backgroundColor:'transparent'});
                      }
                  });

       if($('#direct-link').length > 0 && $('#direct-link').val().length > 0)
         {
           $('#direct-link').removeAttr('disabled');
           $('.article-editor > .body').height(0);
           $('#column-direct').css({backgroundColor:'white'});
         }

       $chk.parents('form:first')
             .submit(function(ev)
                     {
                       if($chk.prop('checked'))
                         {
                           var url = $.trim($('#direct-link').val());
                           if(url == '')
                             {
                               alert('直リンク設定では、URL入力が必須になります。');
                               ev.preventDefault();
                             }
                           else if(!url.match('^https?://'))
                             {
                               alert('httpもしくはhttpsから始まる正しいURLを入力してください。');
                               ev.preventDefault();
                             }
                         }
                     });
     });
 })(jQuery);
