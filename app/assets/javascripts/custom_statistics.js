jQuery(document).ready(function() {
	
	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});

	//get list of popular languages and draw awesome plots
	jQuery.get(
			"/statistics/proglangs.json", null, 
			function(data, status, jqXHR){ render_statistics(data); },
			"json"
	);
	//period filtering: "/statistics/langtrends.json?starts=2012-04&ends=2012-06"
	jQuery.get(
			"/statistics/langtrends.json", null, 
			function(data, status, jqXHR){ render_trends(data);},
			"json"
	);
		
});

var ChartConfig = {
	width : 777,
	height : 400,
	domain_code : "",
	left_padding : 80
}


function generate_random_color(){
	//last zeros are buffer values, because random.gener may generate shorter values sometimes
	var color_string=  "#" + (Math.random()*0xFFFFFF<<0).toString(16) + "000";
	return color_string.substring(0,7);
}

function configure_container(selector, width, height){
	container = jQuery(selector);
	container.css("padding", "5 10 5 10");
	container.css("height", height + 30);
	container.css("width", width+ 10);
}

function print_legend(selector, color_map){

	var legend_html = ['<div class= "legend-container" style = "margin-left:80px; width:100%;">']
	for (var lang in color_map){
		//console.log(lang + ": " + color_map[lang]);
		legend_html.push('<div class=  "legend-item" style="float:left; width: 120px;margin:5px, 10px, 5px, 10px;">');
		legend_html.push('<div class= "legend-key" style="width:15px;float:left;background-color:'+color_map[lang]+';">&nbsp;&nbsp;</div>');
		legend_html.push('<div style "width:107px;float:left;padding-left:5px;">'+ lang +'</div>');
		legend_html.push('<div style="float:clean;"></div></div>');
	}

	legend_html.push("<div>");
	jQuery(selector).append(legend_html.join(""));
}


// ---------------------------------------------------------------
function render_statistics(data){
	//renders awesome summery plots
	var chart_container = "chart_container",		
		chart = new JSChart(chart_container, "bar", ChartConfig.domain_code);
	if (data.length == 0 ){
		console.log("Error:render_statisitics - empty dataset!");
		return null;
	}

	configure_container("#" + chart_container, ChartConfig.width, ChartConfig.height);
	
	chart.setDataArray(data);
	chart.setTitle("Projects per Languages");
	chart.setTitleFontSize(15);
	chart.setAxisReversed(true);
	
	chart.setAxisNameX("", false);
	chart.setAxisNameY("", false);
	chart.setAxisPaddingLeft(ChartConfig.left_padding);
	chart.setAxisValuesFontSizeX(14);
	chart.setBarValuesFontSize(14); 
	//chart.setBarSpacingRatio(5); //change spacing between bars
	chart.setBarOpacity(0.8);
	chart.draw();
	chart.resize(ChartConfig.width, ChartConfig.height);
}

function render_trends(language_map){
	var chart_container = "chart_container2",
		chart_selector = "#" + chart_container,
		chart = new JSChart(chart_container, "line", ChartConfig.domain_code)
		color_map = {};

	configure_container(chart_selector, ChartConfig.width, ChartConfig.height);
	//add data
	chart.setGraphExtend(true);
	chart.setTitle("Number of projects over time");
	chart.setTitleFontSize(15);
	var languages = language_map["data"];
	var i = 1;
	
	Object.keys(languages).forEach(function(lang){
		chart.setDataArray(languages[lang], lang);
		color_map[lang] = generate_random_color();
		chart.setLineColor(color_map[lang],lang);
		chart.setLineOpacity(0.8,lang);
		//chart.setLabelX([i, lang]);
		i += 1;
	});
	chart.draw();
	console.log(color_map);
	chart.setAxisAlignX(true);
	chart.setAxisNameX("", false);
	chart.setAxisNameY("", false);
	chart.setAxisValuesFontSize(14);
	chart.setAxisPaddingLeft(ChartConfig.left_padding);
	
	//chart.setAxisValuesAngle(90);

	var xlabels = language_map["xlabels"]
	//chart.setAxisValuesNumberX(xlabels.length);	
	chart.setShowXValues(false);
	var n = 1;
	for (var i in xlabels){
		label = "" + xlabels[i];
		chart.setLabelX([n++, label]);
	}
		
	chart.draw();
	chart.resize(ChartConfig.width, ChartConfig.height);
	//append legend
	print_legend(chart_selector, color_map);
}