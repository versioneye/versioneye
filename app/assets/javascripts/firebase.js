function start_firebase(limit_size){
	var messageListRef = new Firebase('http://gamma.firebase.com/_versioneye');
	messageListRef.limit(limit_size).on('child_added', function(snapshot, prevName) {
		var messageInfo = snapshot.val();
		if (messageInfo && messageInfo.package && messageInfo.version && messageInfo.url){
			var product = messageInfo.package;
			if (messageInfo.name) {
				product = messageInfo.name
			}
			var version = messageInfo.version;
			var url = messageInfo.url;
			var type = messageInfo.type; 
			var content = "<div class='searchResult' >"
			content += "<ul class='list-row'>"
			content += "<li class='list-cell icon-cell'>"
			if (type && type == "RubyGem" )
				content += "<img src='/assets/prod_type/logo_ruby.png' alt='Ruby'></img>";
			else if (type && type == "PIP")
				content += "<img src='/assets/prod_type/logo_python.png' alt='Python'></img>";
			else if (type && type == "npm")
				content += "<img src='/assets/prod_type/logo_npm.png' alt='Node.js'></img>";
			else if (type && type == "Maven2")
				content += "<img src='/assets/prod_type/logo_java.png' alt='Java'></img>";
			else 
				content += "<img src='/assets/eye_off.png' alt='Software'></img>";						
			content += "</li>"
			content += "<li class='list-cell'><a class='searchResultLink' href='"+url+"'>"+product+" (" + version + ")</a></li>"
			content += "</ul>"
			content += "</div>"
			$('#loadingbar').remove()
			$('#newest').prepend(content).slideDown("slow");
			var result_count =  $('.searchResult').length; 
			if (result_count > limit_size){
				$('#newest div:last-child').remove()
			}
		}	  
	});
}