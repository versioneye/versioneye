function update_lang(language){
	orig_param = language;
	icon_id = "icon_" + orig_param.toLowerCase()
	lang = document.getElementById("lang").value
	language_orig = language;
	language = language + ","
	var rg = new RegExp(language,'i');
	if (lang.search(rg) == -1){
		lang = lang + "," + language
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).className = icon_id + " small on";
		}
	} else {
		lang = lang.replace(language, "")
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).className = icon_id + " small off";
		}		
	}
	lang = lang.replace(",,,", ",") 
	lang = lang.replace(",,", ",") 
	document.getElementById("lang").value = lang
}