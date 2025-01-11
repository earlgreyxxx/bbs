/*******************************************************************************

	ファイル管理ウィンドウのスクリプト

*******************************************************************************/
function getParentJQuery()
{
  return  (window.opener ? window.opener : window.parent).jQuery;
}

function closeUploadWindow()
{
  var $$ = getParentJQuery();
  var $ = jQuery;

  var $filesThis = $('#fshd9a8yf65476f');
  var $filesThat = $$('#gkdfjgd89576984');

  try
    {
      $filesThat.html($filesThis.html());
    }
  catch(e)
    {
      window.alert(e.message);
    }

  closeWindow($$);
}

function closeWindow($$)
{
  if(!$$)
    $$ = getParentJQuery();

  window.opener ? window.close() : $$.simplePopup.Close();
}

(function($)
 {
   $(function()
     {
       $('#submit-upload')
         .click(function(ev)
                {
                  $(this)
                    .parents('form')
                      .submit();
                });
     });


 })(jQuery);