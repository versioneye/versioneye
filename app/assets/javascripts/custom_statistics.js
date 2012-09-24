jQuery(document).ready(function() {
	
	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});

	//get list of popular languages and draw awesome plots
	setTimeout(
		jQuery.get(
			"/statistics/proglangs.json", null, 
			function(data, status, jqXHR){ render_statistics(data);},
			"json"
		),
		3000
	)
	
	
});

function render_statistics(data){
	//renders awesome summery plots
	var chart_container = "chart_container",
		chartX = 777,
		chartY = 400,
		domain_code = "",
		chart = new JSChart(chart_container, "bar", domain_code);
	if (data.length == 0 ){
		console.log("Error:render_statisitics - empty dataset!");
		return null;
	}

	container = jQuery("#"+chart_container);
	container.css("padding", "5 15 5 15");
	container.css("height", chartX + 30);
	container.css("width", chartY + 10);
	
	chart.setDataArray(data);
	chart.setTitle("Popularity of projects by languages");
	chart.setTitleFontSize(15);
	chart.setAxisReversed(true);
	chart.resize(chartX, chartY);
	chart.setAxisNameX("", false);
	chart.setAxisNameY("", false);
	chart.draw();
}