jQuery(document).ready(function() {
	
	jQuery('#q').tbHinter({
		text: "json",
		styleclass: "lp_searchfield_hint"
	});

	render_statistics();
	
});

function render_statistics(){
	var chart_container = "chart_container";
	var chartX = 777;
	var chartY = 400;
	var data = [['java', 30], ['c', 25], ['ruby', 20], ['javascript', 10], ['php', -2]];
	var chart = new JSChart("chart_container", "bar", "domain-code");
	
	container = jQuery("#"+chart_container);
	container.css("height", chartX + 10);
	container.css("padding", "5 10 5 10");
	
	chart.setDataArray(data);
	chart.setAxisReversed(true)
	chart.resize(chartX, chartY)
	chart.draw();
}