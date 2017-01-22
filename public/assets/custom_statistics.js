function reformatDate(dtString, sourceFmt, targetFmt){
  sourceFmt = (typeof sourceFmt !== 'undefined') ?  sourceFmt : "YYYY-MM-DD";
  targetFmt = (typeof targetFmt !== 'undefined') ?  targetFmt : "dddd, Do MMMM";

  return moment(dtString, sourceFmt).format(targetFmt);
};


function getLanguageColor(langName){
  var colorMap = {
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

  var langName_ = langName.toLowerCase(); 
  return ( _.has(colorMap, langName_) ? colorMap[langName_] : colorMap['default']);
}

function renderSummaryPlot(ctx, summaryData){

  var colNames = [], colValues = [], colColors = [];
  var _summaryData = summaryData.sort(function(a,b){
    return (a['value'] <= b['value']) ? 1 : -1;
  }); 

  //build value arrays from the summary doc
  _summaryData.forEach(function(x){
    colNames.push(x['name']);
    colValues.push(x['value']);
    colColors.push(getLanguageColor(x['name']));
  });

  var graphData = {
    labels: colNames,
    datasets: [{
      label: "Number of packages",
      data: colValues,
      backgroundColor: colColors 
    }],
    options: {
      legend: { display: false }
    }
  }

  var plot = new Chart(ctx, {
    type: 'horizontalBar',
    data: graphData
  });
}

function renderTrendPlot(ctx, trendData){
  var dateLabels = [];
  var languageVals = {
    'r'      : [],
    'C#'     : [],
    'java'   : [],
    'ruby'   : [],
    'python' : [],
    'nodejs' : [],
    'php'    : [],
    'clojure': [],
    'objective-c' : []
  }; 

  trendData.forEach(function(x){
    dateLabels.push(reformatDate(x['date'], 'YYYY-MM-DD', 'YYYY.MM'))
    
    _.each(x, function(val, key){
      //collect each language stats into own array
			if(key !== "date"){ languageVals[key].push(val); }
  	});
	
	});

  var datasets = [];
  _.each(languageVals, function(val, key){
    datasets.push({
      label: key,
      data: val,
      borderColor: getLanguageColor(key)
    });
  });

  var graphData = {
    labels: dateLabels,
    datasets: datasets
  };

  var plot = new Chart(ctx, {
    type: 'line',
    data: graphData
  });
}

jQuery(document).ready(function() {

  jQuery('#q').tbHinter({
      text: "json"
  });

  var baseURI = document.location.origin;

  if( jQuery("#plot-summary").length ){
    console.log('Going to render summary plot');
    jQuery.getJSON(
      baseURI + "/statistics/proglangs",
      function(summaryData){
        renderSummaryPlot($("#plot-summary"), summaryData);
      }
    );
  }

  if( jQuery("#plot-trends").length ){
    console.log('Going to render trends container');
    jQuery.getJSON(
      baseURI + "/statistics/langtrends",
      function(trendData){
        renderTrendPlot( $("#plot-trends"), trendData);
      }
    );
  }
});
