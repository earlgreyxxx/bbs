/*******************************************************************************
  記事一覧に挿入されるスクリプト
******************************************************************************/
var sbmtAr = new Array();
function notifyCheckBoxClick(chkb,sbmt,idx)
{
  if(typeof(chkb) == 'string')
    chkb = document.getElementById(chkb);
  if(typeof(sbmt) == 'string')
    sbmt = document.getElementById(sbmt);

  try
    {
      if(!sbmtAr[idx])
        {
          sbmtAr[idx] = 1;
          sbmt.disabled = false;
        }
    }
  catch(e)
    {
      window.alert(e.message);
    }
}

function do_select_action()
{
  if(this.value)
    {
      var $option = jQuery(this).find('option').eq(this.selectedIndex);
      var handler = $option.data('handler');
      var target = $option.data('window');

      if(handler && submitClone)
      {
        submitClone.call({href: this.value},null);
      }
      else
      {
        if(this.value)
        {
          if(target)
            window.open(this.value,target);
          else
            location.href=this.value;
        }
      }
    }

  this.selectedIndex = 0;
}
