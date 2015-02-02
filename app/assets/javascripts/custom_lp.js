
jQuery(document).ready(function() {

	jQuery('#q').tbHinter({
		text: "Search for a software library"
	});

  jQuery('#what_is_versioneye_link').on('click', function (e) {
    $.scrollTo($('#what_is_versioneye'), 600,  {easing:'easeOutCubic'});
    return false;
  });

  jQuery('#packagemanagers_link').on('click', function (e) {
    $.scrollTo($('#packagemanagers'), 800,  {easing:'easeOutCubic'});
    return false;
  });

  jQuery('#integration_link').on('click', function (e) {
    $.scrollTo($('#integration'), 800,  {easing:'easeOutCubic'});
    return false;
  });

  jQuery('#api_link').on('click', function (e) {
    $.scrollTo($('#api'), 800,  {easing:'easeOutCubic'});
    return false;
  });

  jQuery('#reasons_link').on('click', function (e) {
    $.scrollTo($('#reasons'), 800,  {easing:'easeOutCubic'});
    return false;
  });

  jQuery('#signup_link').on('click', function (e) {
    $.scrollTo($('#register_today'), 800,  {easing:'easeOutCubic'});
    return false;
  });

  jQuery('#back_to_top').on('click', function (e) {
    $.scrollTo($('#login'), 1000,  {easing:'easeOutCubic'});
    return false;
  });

  initialize_searchbox();
});

function regulate_height(){
  myHeight = window.innerHeight;
  if (myHeight > 410) {
    padding_height = myHeight - 428;
    reasons_height = (myHeight - 482) / 2;
    features_height = (myHeight - 500) / 2;
    document.getElementById("search_section").style.cssText = "padding-bottom: " + padding_height + "px;";
    document.getElementById("reasons").style.cssText = "padding-top: " + reasons_height + "px; padding-bottom: " + reasons_height +"px;";
    document.getElementById("features").style.cssText = "padding-top: " + features_height + "px; padding-bottom: " + features_height +"px;";
  } else {
    document.getElementById("search_section").style.cssText = "padding-bottom: 65px";
  }
  setTimeout( function(){ regulate_height() }  , 1000 );
}

function initialize_searchbox(){
  console.log("Initializing searchbox");
  var $ = jQuery;
  $('input#q').typeahead({
    name: 'autocomplete',
    limit: 10,
    allowDuplicates: true,
    remote: {
      url: "/package/autocomplete?term=%QUERY"
    },
    engine: Hogan,
    template: [
      '<div>',
          '<img src="/assets/language/{{ language }}.png" alt="{{ language }}" class = "pull-left" style = "height: 2.0em;" />',
          '<p>',
              '<a href = "{{ url }}">',
                '<strong>{{ name }}</strong>',
               '</a>',
             ' - {{ description }}',
           '</p>',
      '</div>'
    ].join('')
  });

  $('input#q').focus();
}
