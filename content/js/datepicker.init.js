/*******************************************************************************

  Initializing datepicker...

*******************************************************************************/
(function($,undefined)
 {
   var toDoubleDigit = function(n)
     {
       return (n < 10 && n >= 0) ?  '0' + n : n;
     };

   var now = new Date();
   var locale_ja =
     {
       days: ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"],
       daysShort: ["日", "月", "火", "水", "木", "金", "土", "日"],
       daysMin: ["日", "月", "火", "水", "木", "金", "土", "日"],
       months: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
       monthsShort: ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"],
       weekMin: '週'
     };
   
   var onBeforeShowCb = function(selector)
     {
       var id_1 = selector + '-1';

       var date = $(id_1).val();
       $(id_1).DatePickerSetDate(date.match(/(\d{4})年(\d{1,2})月(\d{1,2})日/) ? date : now, true);
     };

   var onChangeCb = function(selector,formated,dates)
     {
       var id_0 = selector + '-0';
       var id_1 = selector + '-1';

       old = $(id_1).val();

       $(id_0).val([dates.getFullYear(),toDoubleDigit(dates.getMonth()+1),toDoubleDigit(dates.getDate())].join('/'));
       $(id_1).val(formated);

       if(old !== formated)
         $(id_1).DatePickerHide();
     };

   //
   $(function()
     {
       $('#np-1').DatePicker(
         {
           format:'Y年m月d日',
           date: now,
           current: now,
           start: 1,
           locale: locale_ja,
           onBeforeShow: function()
             {
               onBeforeShowCb('#np');
             },
           onChange: function(formated, dates)
             {
               onChangeCb('#np',formated,dates);
             }
         });

       $('#submit-clear-date')
         .click(function()
                {
                  $('#np-0').val('');
                  $('#np-1').val('設定なし');
                });
     });

 })(jQuery);
 