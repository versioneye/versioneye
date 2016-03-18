function update_lang(language){
  // console.debug("Updating language with new language: " + language)
  orig_param = language;
  icon_id    = "icon_" + orig_param.toLowerCase()
  lang       = document.getElementById("lang").value
  // console.debug("lang values: " + lang)
  var rg = new RegExp('\\b' + language + '\\b','ig');
  if (lang.search(rg) == -1){
    lang = lang + "," + language
  } else {
    lang = lang.replace(rg, "")
  }
  lang = lang.replace(/[\,]+/, ",") // remove multiple comas
  lang = lang.replace(/^[\,]+/, "") // remove coma at the beginning of string
  lang = lang.replace(/[\,]+$/, "") // remove coma at the end of string
  document.getElementById("lang").value = lang
  // console.debug("new lang values: " + lang)
}
