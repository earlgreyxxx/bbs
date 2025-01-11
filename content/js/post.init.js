/*******************************************************************************
  Initialization for 'add-new' process

  formats: 
  json = {
    items         : array of postdata
    attribs       : 
    attached      : array of attached file data { name, filename}
    attached_ords : array for orders of attached files.[name1,name2,name3....]
    direct        : direct link url if specfied, others for null
    headline      : 
    image         : image filename
    lastupdate    : last update time of article
    notify        :
    notify_to     :
    options       : array of options
    outline       :
    public        : hide(1) or show(0)
    registdate    : created time of article
  }
*******************************************************************************/



var L_KEY = 0,L_TITLE = 1,L_DATE = 2,L_BODY = 3,L_ATTR = 4,L_FILE = 5,L_DELETE = 6;
(function($)
 {
   if(!POSTDATA)
     return;

   var json = POSTDATA;

   $('.article-editor input[name="title"]').val(json.items[L_TITLE]);
   $('.article-editor input[name="date"]').val(json.items[L_DATE]);
   $('.article-editor textarea[name="body"]').val(json.items[L_BODY]);

   $('#chkb_hl').prop('checked',json.headline);
   $('#chkb_resv').prop('checked',!json.public);

   var directlink = json.direct;

   // if article is direct link , copy attribute
   if(directlink.match(/^http/))
     {
       $('#is-direct-link').prop('checked','checked');
       $('#direct-link')
         .removeAttr('disabled')
           .val(decodeURIComponent(directlink));
     }

   if(json.options.length > 0)
     $.each(json.options,function(i,v) { $('.article-editor input[name="option_'+i+'"]').val(v); });

   $('.article-editor select[name="notification"]').prop('selectedIndex',json.notify);

   if(json.notify_to)
     {
       var d = new Date(parseInt(json.notify_to) * 1000);
       $('#np-0').val([d.getFullYear(),d.getMonth() + 1,d.getDate()].join('-'));
       $('#np-1').val(d.getFullYear() + '年' + (d.getMonth() + 1) + '月' + d.getDate() + '日');
     }
 })(jQuery);

