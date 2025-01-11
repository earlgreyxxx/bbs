/*******************************************************************************

  Initializing TinyMCE...

*******************************************************************************/
tinymce.init({
  selector: 'textarea',  // change this value according to your HTML
  auto_focus: 'element1',
  language : 'ja',
  content_css : SCRIPT_DIR,
  min_height: 300,
  menubar: false,
  plugins: "textcolor colorpicker link code",
  toolbar1: "cut copy | undo redo | fontsizeselect | bold underline strikethrough | forecolor backcolor | removeformat ",
  toolbar2: "indent outdent alignleft aligncenter alignright alignjustfy | bullist numlist | link unlink | pastetext | code",
  forced_root_block: 'div',
  fontsize_formats: '60% 80% 120% 140% 180% 200% 240% 270%',
  contextmenu: 'link unlink | undo redo | removeformat'
});

