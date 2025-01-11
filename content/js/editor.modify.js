/*******************************************************************************
  修正画面のエディターに挿入されるスクリプト
******************************************************************************/
var setStrColor;
var openUploadWin;
var openManageWin;

(function($,fmanage)
 {
   var params = {
     limit : { width: 600, height: 600},
     openHere: false,
     caption: null,
     frameCSS: { background: '#f3f3f3' }
   };

   //初期化処理
   $(function()
     {
       $('#submit-add-new')
         .click(function(ev)
                {
                  ev.preventDefault();
                  ev.stopPropagation();

                  $.simplePopup.Invoke(this,params);
                  $.simplePopup.getContext().overlay.unbind();
                });

       var radioChecked = {fontWeight: 'bold',color: 'black'};
       var radioUnchecked = {fontWeight: 'normal',color: 'grey'};

       $('#ac_ren,#ac_rm')
         .change(function()
                 {
                   $(this)
                     .next('label')
                       .find('span')
                         .css(this.checked ? radioChecked : radioUnchecked)
                       .end()
                     .end()
                       .siblings('input[type="radio"]')
                         .next('label')
                           .find('span')
                             .css(this.checked ? radioUnchecked : radioChecked);
                 });


       $('#submit-file-manager')
         .click(function(ev)
                {
                  ev.preventDefault();
                  ev.stopPropagation();

                  var $a = $(this);
                  var $ren = $('#ac_ren');
                  var $rmv = $('#ac_rm');
                  var ac = '';

                  if($ren.prop('checked'))
                    {
                      ac = 'rename';
                    }
                  else if($rmv.prop('checked'))
                    {
                      ac = 'remove';
                    }
                  else
                    {
                      window.alert('処理内容を選択してください');
                      return;
                    }

                  var url = $a.attr('href');
                  var queries = this.search.slice(1).split('&');
                  var qs = {};
                  $.each(queries,
                         function(i,v)
                         {
                           var ps = v.split('=');
                           qs[$.trim(ps[0])] = $.trim(ps[1]);
                         });

                  qs['ac'] = ac;
                  qs['at'] = 5;

                  queries = [];
                  $.each(qs,function(k,v) {queries.push(k + '=' + v);});

                  $a.attr('href',
                          this.protocol + '//' + this.hostname + this.pathname + '?' + queries.join('&'));

                  $.simplePopup.Invoke(this,$.extend({},params,{limit: {width: 800}}));
                  $.simplePopup.getContext().overlay.unbind();
                });
     });

 })(jQuery,CGI);

