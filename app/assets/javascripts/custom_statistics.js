function init_plots(){
  require(["/assets/libs/d3.v3.min.js",
           "/assets/plots/horizontalBarChart.js",
           "/assets/plots/multiTimeline.js"],
          function(d3, BarChart, MultiTimeline){
    console.debug("Going to render D3 plots.");
    jQuery("#plot_latest").html("");

    barChart = new BarChart({
      selector: "#plot_latest",
      width: 777,
      height: 400,
      title: "Projects per language"
    });

    barChart.loadAndRender("/statistics/proglangs");

    jQuery("#plot_trends").html("");
    trends = new MultiTimeline({
      selector: "#plot_trends",
      legend: {selector: "#plot_trends_legend"},
      width: 777,
      height: 400,
      title: "Number of projects over time"
    });
    trends.loadAndRender("/statistics/langtrends");
  });
}


jQuery(document).ready(function() {

    jQuery('#q').tbHinter({
        text: "json"
    });

    /*period filtering: "/statistics/langtrends.json?starts=2012-04&ends=2012-06"
    jQuery.get(
            "/statistics/langtrends.json", null,
            function(data, status, jqXHR){ render_trends(data); },
            "json"
    );
    */
});

var ChartConfig = {
    width : 777,
    height : 400,
    domain_code : "",
    left_padding : 80,
  right_padding : 80,
    font_family : "Helvetica Neue, Helvetica, sans-serif,  Arial",
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
        "clojure" : "#999999"
    }
}


function configure_container(selector, width, height){
    container = jQuery(selector);
    container.css("padding", "5 10 5 10");
    container.css("height", height + 30);
    container.css("width", width+ 10);
}

function print_legend(selector, color_map){

    var legend_html = ['<div class= "legend-container" style = "margin: 5px 20px 5px 80px; width:90%;">']
    for (var lang in color_map){
        legend_html.push('<div class=  "legend-item" style="float: left; line-height: 110%; padding: 5px 15px 5px 5px;">');
        legend_html.push('<div class= "legend-key" style="width: 15px; height: 14px; float:left; background-color:' + color_map[lang]+';">&nbsp;&nbsp;</div>');
        legend_html.push('<div style= "font-size: '+ChartConfig.font_size+'px;float:left;padding-left:5px;">'+ lang +'</div>');
        legend_html.push('<div style="float:clean;"></div></div>');
    }

    legend_html.push("<div>");
    jQuery(selector).append(legend_html.join(""));
}


function render_trends(language_map){

    if ((language_map == undefined) || language_map.data.length == 0 ){
        console.log("Error:render_trends - empty dataset!");
        return null;
    }

    ChartConfig.domain_code = "aa7843dd73cc5af13f5b53855cf92ac0";

    var chart_container = "chart_container_trends";
    var chart_selector = "#" + chart_container;
    var chart = new JSChart(chart_container, "line", ChartConfig.domain_code);
    var color_map = {};

    configure_container(chart_selector, ChartConfig.width, ChartConfig.height);
    //add data
    chart.setGraphExtend(true);
    chart.setTitle("Number of projects over time");
    chart.setTitleFontSize(15);
    var languages = language_map["data"];
    var i = 1;

    Object.keys(languages).forEach(function(lang){

        chart.setDataArray(languages[lang], lang);
        var normalized_lang =  lang.toLowerCase().trim();
        var line_color = ChartConfig.color_map[normalized_lang] || ChartConfig.color_map["default"];
        chart.setLineColor(line_color, lang);
        color_map[lang] = line_color; //save it for legend
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
    chart.setAxisValuesFontFamily(ChartConfig.font_family);
    chart.setLabelFontFamily(ChartConfig.font_family);
    //chart.setAxisValuesAngle(90);

    var xlabels = language_map["xlabels"]
    //chart.setAxisValuesNumberX(xlabels.length);
    chart.setShowXValues(false);
    var n = 1;
    for (var i in xlabels){
        label = xlabels[i].toString();
        chart.setLabelX([n++, label]);
    }

    //chart.setLabelFontSize(ChartConfig.font_size);
    chart.draw();
    chart.resize(ChartConfig.width, ChartConfig.height);
    //append legend
    print_legend(chart_selector, color_map);
}
