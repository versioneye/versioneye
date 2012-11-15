function update_lang(language){
	orig_param = language;
	icon_id = orig_param.toLowerCase() + "_icon"
	lang = document.getElementById("lang").value
	language_orig = language;
	language = language + ","
	var rg = new RegExp(language,'i');
	if (lang.search(rg) == -1){
		lang = lang + "," + language
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).style.borderBottom = "2px solid #f9b323";
			if (orig_param == "Java"){
				document.getElementById(icon_id).style.backgroundPosition = "-611px 0";
			} else if (orig_param == "Ruby"){
				document.getElementById(icon_id).style.backgroundPosition = "-325px 0";
			} else if (orig_param == "Python"){
				document.getElementById(icon_id).style.backgroundPosition = "-538px -57px";
			} else if (orig_param == "Node.JS"){
				document.getElementById(icon_id).style.backgroundPosition = "-361px -53px";
			} else if (orig_param == "R"){
				document.getElementById(icon_id).style.backgroundPosition = "--441px 0";
			} else if (orig_param == "JavaScript"){
				document.getElementById(icon_id).style.backgroundPosition = "-420px -53px";
			} else if (orig_param == "PHP"){
				document.getElementById(icon_id).style.backgroundPosition = "-671px 0";
			} else if (orig_param == "Clojure"){
				document.getElementById(icon_id).style.backgroundPosition = "-654px -59px";
			}
		}
	} else {
		lang = lang.replace(language, "")
		if (document.getElementById(icon_id) != null){
			document.getElementById(icon_id).style.borderBottom = "0px solid #f9b323";
			if (orig_param == "Java"){
				document.getElementById(icon_id).style.backgroundPosition = "-554px 0";
			} else if (orig_param == "Ruby"){
				document.getElementById(icon_id).style.backgroundPosition = "-383px 0";
			} else if (orig_param == "Python"){
				document.getElementById(icon_id).style.backgroundPosition = "-596px -58px";
			} else if (orig_param == "Node.JS"){
				document.getElementById(icon_id).style.backgroundPosition = "-361px -53px";
			} else if (orig_param == "R"){
				document.getElementById(icon_id).style.backgroundPosition = "-500px 0";
			} else if (orig_param == "JavaScript"){
				document.getElementById(icon_id).style.backgroundPosition = "-479px -53px";
			} else if (orig_param == "PHP"){
				document.getElementById(icon_id).style.backgroundPosition = "-729px 0";
			} else if (orig_param == "Clojure"){
				document.getElementById(icon_id).style.backgroundPosition = "-712px -58px";
			}
		}		
	}
	lang = lang.replace(",,,", ",") 
	lang = lang.replace(",,", ",") 
	document.getElementById("lang").value = lang
}