var markers = new Array();

function initialize_profile(address) {
	if (address == null || address == "" ){
		address = "Berlin"
	}
	var map_for_user_profile = document.getElementById("map_for_user_profile");
	var geo = new google.maps.Geocoder;
    if (map_for_user_profile != null){
    	geo.geocode({'address': address},function(results, status){
			if (status == google.maps.GeocoderStatus.OK) {
				var latlng = results[0].geometry.location
				var myOptions = {
			        zoom: 5,
			        center: latlng,
			        mapTypeId: google.maps.MapTypeId.ROADMAP
			    };
			    map = new google.maps.Map(map_for_user_profile, myOptions);
			    var marker = new google.maps.Marker({position: latlng, map: map});
			} else {
				// alert("Geocode was not successful for the following reason: " + status);
                alert("Sorry. We are not able to display the location on Google Maps. Maybe you should edit your location.");
			}
		});
    }
}

function initialize_jobs() {
    var map_for_jobs = document.getElementById("map_for_jobs");
    if (map_for_jobs != null){
        initialize_map_for_jobs(map_for_jobs);
		placeMarker( create_job_content('Java Entwickler', 'http://www.megapart.de/de/projekte.php?id=2784') , 48, 11);
		placeMarker( create_job_content('Web Entwickler', 'http://www.megapart.de/de/projekte.php?id=2772') , 51.1, 11);
		placeMarker( create_job_content('Web Entwickler', 'http://www.megapart.de/de/projekte.php?id=2772') , 51.1, 11);
		clusterMarker();
    }
}

function initialize_map_for_jobs(htmlElement) {
    var latlng = new google.maps.LatLng(51.0, 11.4666667);
    var myOptions = {
        zoom: 5,
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(htmlElement, myOptions);
}

function create_job_content(title, link){
    var contentString = '<div >'+
       '<h4>' + title + ' </h4>' +
       '<a href="'+link+'" target="_NEW">details</a><br/>' +
       '</div>';
    return contentString;
}

function placeMarker(contentString, lat, lng){
    var latlng = new google.maps.LatLng(lat, lng);
    var marker = new google.maps.Marker({position: latlng, map: map});
    markers.push(marker);
    var infowindow = new google.maps.InfoWindow({
        content: contentString
    });
    google.maps.event.addListener(marker, 'click', function() {
      infowindow.open(map, marker);
    });
}

function clusterMarker(){
    var mcOptions = {gridSize: 40, maxZoom: 0};
    new MarkerClusterer(map, markers, mcOptions);
}
