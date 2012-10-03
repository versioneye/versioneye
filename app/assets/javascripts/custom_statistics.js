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
	left_padding : 80,
	font_size : 14,
	color_map : {
		"default" : "#333333",
		"java" : "#544FD6",
		"ruby" : "#DC143C",
		"c" : "#33A1C9",
		"c++": "#104E8B",
		"c#" : "#00BFFF",
		"groovy": "#006400",
		"python" : "#EE7600",
		"r" : "#8B7D6B",
		"javascript" : "#9ACD32",
		"node.js" : "#6B8E23",
		"php" : "#8B6914",
	}
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
		lang = lang.toLowercase().trim();
		//console.log(lang + ": " + color_map[lang]);
		legend_html.push('<div class=  "legend-item" style="float:left; width: 120px;margin:5px, 10px, 5px, 10px;">');
		legend_html.push('<div class= "legend-key" style="width:15px;float:left;background-color:' + ChartConfig.color_map[lang]+';">&nbsp;&nbsp;</div>');
		legend_html.push('<div style "font-size:'+ChartConfig.font-size+'px; width:107px;float:left;padding-left:5px;">'+ lang +'</div>');
		legend_html.push('<div style="float:clean;"></div></div>');
	}

	legend_html.push("<div>");
	jQuery(selector).append(legend_html.join(""));
}


// ---------------------------------------------------------------
function render_statistics(data){
	//renders awesome summery plots
	var chart_container = "chart_container_projects";
	var chart = new JSChart(chart_container, "bar", ChartConfig.domain_code);
	if ((data == undefined) || data.length == 0 ){
		console.log("Error:render_statistics - empty dataset!");
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
	chart.setAxisValuesFontSizeX(ChartConfig.font_size);
	chart.setBarValuesFontSize(ChartConfig.font_size); 
	//chart.setBarSpacingRatio(5); //change spacing between bars
	chart.setBarOpacity(0.8);
	chart.draw();
	chart.resize(ChartConfig.width, ChartConfig.height);
}

function render_trends(language_map){
	console.log( language_map == undefined);
	if ((language_map == undefined) || language_map.data.length == 0 ){
		console.log("Error:render_trends - empty dataset!");
		return null;
	}

	var chart_container = "chart_container_trends";
	var chart_selector = "#" + chart_container;
	var chart = new JSChart(chart_container, "line", ChartConfig.domain_code);
	var	color_map = {};

	configure_container(chart_selector, ChartConfig.width, ChartConfig.height);
	//add data
	chart.setGraphExtend(true);
	chart.setTitle("Number of projects over time");
	chart.setTitleFontSize(15);
	var languages = language_map["data"];
	var i = 1;
	
	Object.keys(languages).forEach(function(lang){
		var lang = lang.toLowercase().trim()
		chart.setDataArray(languages[lang], lang);		
		chart.setLineColor(ChartConfig.color_map[lang],lang);
		chart.setLineOpacity(0.8, lang);
		//chart.setLabelX([i, lang]);
		i += 1;
	});
	chart.draw();
	chart.setAxisAlignX(true);
	chart.setAxisNameX("", false);
	chart.setAxisNameY("", false);
	chart.setAxisValuesFontSize(ChartConfig.font_size);
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
	print_legend(chart_selector, ChartConfig.color_map);
}