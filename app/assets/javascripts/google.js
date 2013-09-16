
var _gaq = _gaq || [];
_gaq.push(['_setAccount', 'UA-32702672-1']);
_gaq.push(['_trackPageview']);

(function() {
  var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
})();

function page_view(path){
  if (_gaq){
    _gaq.push(['_trackPageview', path]);
  } else {
    ga('send', 'pageview', path);
  }
}
