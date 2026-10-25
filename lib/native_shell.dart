/// Aplica look nativo sobre el portal web (login persona + panel).
class NativeShell {
  static const injectJs = r'''
(function () {
  document.body.classList.add('is-native');
  var hide = ['.site-header','.site-footer','.wa-float','.cookie-banner','.access-modal','.nav-toggle'];
  hide.forEach(function (sel) {
    document.querySelectorAll(sel).forEach(function (el) {
      el.style.display = 'none';
    });
  });
  if (document.getElementById('sw-native-css')) return;
  var css = document.createElement('style');
  css.id = 'sw-native-css';
  css.textContent = [
    '.site-header,.site-footer,.wa-float,.cookie-banner,.access-modal,.nav-toggle{display:none!important}',
    'body{background:#0b1220!important}',
    '.page-hero{padding:48px 0 8px!important}',
    '.page-hero h1{font-size:1.85rem!important}',
    '.form-card{background:transparent!important;border:0!important;box-shadow:none!important;padding:0!important}',
    '.form-card input{height:48px!important;font-size:16px!important;border-radius:14px!important}',
    '.form-card .btn{width:100%!important;height:50px!important}'
  ].join('');
  document.head.appendChild(css);
})();
''';
}
