function update_lang(language){
	orig_param = language;
	icon_id = orig_param.toLowerCase() + "_icon"
	lang = document.getElementById("lang").value

	ext_lang = null;
	ext_lang_field = document.getElementById("ext_lang") 
	if (ext_lang_field){
		ext_lang = ext_lang_field.value	
	}

	language_orig = language;
	language = language + ","
	var rg = new RegExp(language,'i');
	if (lang.search(rg) == -1){
		lang = lang + "," + language
		if (ext_lang){
			ext_lang = ext_lang + "," + language	
		}
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).style.borderBottom = "2px solid #f9b323";
			if (orig_param == "Java"){
				document.getElementById(icon_id).style.backgroundPosition = "-614px -57px";
			} else if (orig_param == "Ruby"){
				document.getElementById(icon_id).style.backgroundPosition = "-785px 0";
			} else if (orig_param == "Python"){
				document.getElementById(icon_id).style.backgroundPosition = "-728px -57px";
			} else if (orig_param == "Node.JS"){
				document.getElementById(icon_id).style.backgroundPosition = "-557px 0";
			} else if (orig_param == "R"){
				document.getElementById(icon_id).style.backgroundPosition = "-614px 0";
			} else if (orig_param == "JavaScript"){
				document.getElementById(icon_id).style.backgroundPosition = "-842px 0";
			} else if (orig_param == "PHP"){
				document.getElementById(icon_id).style.backgroundPosition = "-443px -57px";
			} else if (orig_param == "Clojure"){
				document.getElementById(icon_id).style.backgroundPosition = "-443px 0";
			}
		}
	} else {
		lang = lang.replace(language, "")
		if (ext_lang){
			ext_lang = ext_lang.replace(language, "")
		}
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).style.borderBottom = "0px solid #f9b323";
			if (orig_param == "Java"){
				document.getElementById(icon_id).style.backgroundPosition = "-956px -57px";
			} else if (orig_param == "Ruby"){
				document.getElementById(icon_id).style.backgroundPosition = "-557px -57px";
			} else if (orig_param == "Python"){
				document.getElementById(icon_id).style.backgroundPosition = "-785px -57px";
			} else if (orig_param == "Node.JS"){
				document.getElementById(icon_id).style.backgroundPosition = "-500px -57px";
			} else if (orig_param == "R"){
				document.getElementById(icon_id).style.backgroundPosition = "-671px -57px";
			} else if (orig_param == "JavaScript"){
				document.getElementById(icon_id).style.backgroundPosition = "-842px -57px";
			} else if (orig_param == "PHP"){
				document.getElementById(icon_id).style.backgroundPosition = "-671px 0";
			} else if (orig_param == "Clojure"){
				document.getElementById(icon_id).style.backgroundPosition = "-728px 0";
			}
		}		
	}
	lang = lang.replace(",,,", ",") 
	lang = lang.replace(",,", ",") 
	document.getElementById("lang").value = lang
	if (ext_lang){
		ext_lang = ext_lang.replace(",,", ",") 
		document.getElementById("ext_lang").value = ext_lang
	}	
}