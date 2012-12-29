function update_lang(language){
    console.debug("Updating language with new language: " + language)

    orig_param = language;
	icon_id = "icon_" + orig_param.toLowerCase()
	lang = document.getElementById("lang").value
	console.debug("lang values:")
    console.debug(lang)
    language_orig = language;
	var rg = new RegExp(language,'ig');
	if (lang.search(rg) == -1){
		lang = lang + "," + language
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).className = icon_id + " small on";
		}
	} else {
		lang = lang.replace(rg, "")
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).className = icon_id + " small off";
		}		
	}

	lang = lang.replace(/[\,]+/, ",") //remove multiple comas
    lang = lang.replace(/^[\,]+/, "") //remove coma at the beginning of string
    lang = lang.replace(/[\,]+$/, "") // remove coma at the end of string
	document.getElementById("lang").value = lang
}
