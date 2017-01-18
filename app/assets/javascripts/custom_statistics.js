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
  var _summaryData = summaryData.sort(function(a,b){ return a['value'] < b['value']; }); 

  //build value arrays from the summary doc
  _summaryData.forEach(function(x){
    colNames.push(x['name']);
    colValues.push(x['value']);
    colColors.push(getLanguageColor(x['name']));
  });

  var graphData = {
    labels: colNames,
    datasets: [{
      label: "The biggest package manager",
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
    
    for(var [key, val] of Object.entries(x)){
      if(key !== "date"){
        languageVals[key].push(val);
      }
    }
  });

  var datasets = [];
  for(var [key, val] of Object.entries(languageVals)){
    datasets.push({
      label: key,
      data: val,
      borderColor: getLanguageColor(key)
    });
  }

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

  var summaryData = [{"name":"Ruby","value":131373},{"name":"Python","value":102999},{"name":"Node.JS","value":395375},{"name":"PHP","value":203301},{"name":"Java","value":208468},{"name":"C#","value":88818},{"name":"R","value":10772},{"name":"Clojure","value":18063},{"name":"Objective-C","value":26651}]

  var trendData = [{"date":"2012-04-01","ruby":35932,"python":16282,"nodejs":7916,"php":0,"java":43952,"C#":0,"r":0,"clojure":0,"objective-c":0},{"date":"2012-05-01","ruby":37342,"python":16861,"nodejs":8852,"php":1,"java":44270,"C#":0,"r":0,"clojure":0,"objective-c":0},{"date":"2012-06-01","ruby":38715,"python":17530,"nodejs":9783,"php":1,"java":45135,"C#":0,"r":2203,"clojure":0,"objective-c":0},{"date":"2012-07-01","ruby":40200,"python":18225,"nodejs":10866,"php":1,"java":47118,"C#":0,"r":2252,"clojure":0,"objective-c":0},{"date":"2012-08-01","ruby":41633,"python":18930,"nodejs":11835,"php":2133,"java":47671,"C#":0,"r":2285,"clojure":0,"objective-c":0},{"date":"2012-09-01","ruby":42987,"python":19649,"nodejs":11835,"php":2761,"java":47987,"C#":0,"r":2326,"clojure":0,"objective-c":0},{"date":"2012-10-01","ruby":44323,"python":20341,"nodejs":11835,"php":3516,"java":48340,"C#":0,"r":2370,"clojure":0,"objective-c":0},{"date":"2012-11-01","ruby":45771,"python":21095,"nodejs":11835,"php":4214,"java":51788,"C#":0,"r":2410,"clojure":3236,"objective-c":0},{"date":"2012-12-01","ruby":47299,"python":21955,"nodejs":11835,"php":5380,"java":53875,"C#":0,"r":2459,"clojure":3405,"objective-c":0},{"date":"2013-01-01","ruby":48705,"python":22643,"nodejs":19781,"php":6263,"java":56478,"C#":0,"r":2493,"clojure":3572,"objective-c":0},{"date":"2013-02-01","ruby":50228,"python":23579,"nodejs":21845,"php":7463,"java":57761,"C#":0,"r":2534,"clojure":3798,"objective-c":0},{"date":"2013-03-01","ruby":51840,"python":24198,"nodejs":23756,"php":8688,"java":59104,"C#":0,"r":2574,"clojure":3953,"objective-c":0},{"date":"2013-04-01","ruby":53685,"python":25403,"nodejs":26492,"php":10050,"java":59770,"C#":0,"r":2623,"clojure":4183,"objective-c":0},{"date":"2013-05-01","ruby":55420,"python":26311,"nodejs":29020,"php":11443,"java":65376,"C#":0,"r":2664,"clojure":4362,"objective-c":0},{"date":"2013-06-01","ruby":57171,"python":27296,"nodejs":31601,"php":12714,"java":71099,"C#":0,"r":2710,"clojure":4570,"objective-c":0},{"date":"2013-07-01","ruby":58686,"python":28183,"nodejs":34201,"php":14023,"java":71885,"C#":0,"r":2742,"clojure":4570,"objective-c":0},{"date":"2013-08-01","ruby":60363,"python":29201,"nodejs":37253,"php":15624,"java":74298,"C#":0,"r":2788,"clojure":4841,"objective-c":0},{"date":"2013-09-01","ruby":62037,"python":30183,"nodejs":40182,"php":17140,"java":82868,"C#":0,"r":2830,"clojure":6987,"objective-c":0},{"date":"2013-10-01","ruby":63504,"python":31069,"nodejs":43371,"php":18712,"java":83696,"C#":0,"r":2859,"clojure":7200,"objective-c":0},{"date":"2013-11-01","ruby":65299,"python":32096,"nodejs":46647,"php":20356,"java":84614,"C#":0,"r":2900,"clojure":7409,"objective-c":0},{"date":"2013-12-01","ruby":66876,"python":33010,"nodejs":50282,"php":22065,"java":86797,"C#":0,"r":2942,"clojure":7668,"objective-c":2986},{"date":"2014-01-01","ruby":68384,"python":34141,"nodejs":53665,"php":23870,"java":87458,"C#":0,"r":2987,"clojure":7887,"objective-c":3262},{"date":"2014-02-01","ruby":69952,"python":35358,"nodejs":58447,"php":25978,"java":89482,"C#":0,"r":3044,"clojure":8177,"objective-c":3572},{"date":"2014-03-01","ruby":71636,"python":36316,"nodejs":62784,"php":28063,"java":91098,"C#":0,"r":3088,"clojure":8430,"objective-c":3896},{"date":"2014-04-01","ruby":73283,"python":37533,"nodejs":67689,"php":30300,"java":93013,"C#":0,"r":3144,"clojure":8693,"objective-c":4151},{"date":"2014-05-01","ruby":75142,"python":38664,"nodejs":72792,"php":32499,"java":96035,"C#":0,"r":3192,"clojure":8963,"objective-c":4680},{"date":"2014-06-01","ruby":76751,"python":39927,"nodejs":77015,"php":34898,"java":97963,"C#":0,"r":3248,"clojure":9275,"objective-c":4937},{"date":"2014-07-01","ruby":78257,"python":41147,"nodejs":81179,"php":40129,"java":98502,"C#":0,"r":3300,"clojure":9499,"objective-c":5429},{"date":"2014-08-01","ruby":80866,"python":49276,"nodejs":87384,"php":42508,"java":98502,"C#":0,"r":6274,"clojure":9760,"objective-c":5783},{"date":"2014-09-01","ruby":89478,"python":50756,"nodejs":93502,"php":45104,"java":105327,"C#":0,"r":6342,"clojure":10055,"objective-c":6165},{"date":"2014-10-01","ruby":90988,"python":52165,"nodejs":99396,"php":47333,"java":108090,"C#":0,"r":6404,"clojure":10384,"objective-c":6485},{"date":"2014-11-01","ruby":92604,"python":53598,"nodejs":105672,"php":49985,"java":110034,"C#":0,"r":6461,"clojure":10653,"objective-c":6786},{"date":"2014-12-01","ruby":94333,"python":55027,"nodejs":112081,"php":52724,"java":113309,"C#":0,"r":6518,"clojure":10928,"objective-c":7111},{"date":"2015-01-01","ruby":95813,"python":56370,"nodejs":120052,"php":55373,"java":115973,"C#":0,"r":6566,"clojure":11189,"objective-c":7437},{"date":"2015-02-01","ruby":97514,"python":57855,"nodejs":127316,"php":58214,"java":122003,"C#":0,"r":6613,"clojure":11516,"objective-c":7834},{"date":"2015-03-01","ruby":99248,"python":59325,"nodejs":133350,"php":60873,"java":124345,"C#":0,"r":6672,"clojure":11792,"objective-c":8261},{"date":"2015-04-01","ruby":101147,"python":61053,"nodejs":142232,"php":64909,"java":127618,"C#":0,"r":6730,"clojure":12206,"objective-c":8873},{"date":"2015-05-01","ruby":102844,"python":62724,"nodejs":150222,"php":68000,"java":129869,"C#":0,"r":6784,"clojure":12475,"objective-c":9428},{"date":"2015-06-01","ruby":104488,"python":64469,"nodejs":158718,"php":71354,"java":132390,"C#":0,"r":7444,"clojure":12774,"objective-c":10061},{"date":"2015-07-01","ruby":106079,"python":66067,"nodejs":166652,"php":74493,"java":136510,"C#":0,"r":7577,"clojure":13028,"objective-c":10646},{"date":"2015-08-01","ruby":107710,"python":67882,"nodejs":175840,"php":78432,"java":140148,"C#":0,"r":7647,"clojure":13337,"objective-c":11202},{"date":"2015-09-01","ruby":109245,"python":69643,"nodejs":185802,"php":83012,"java":143786,"C#":0,"r":7647,"clojure":13607,"objective-c":11806},{"date":"2015-10-01","ruby":110653,"python":71374,"nodejs":196011,"php":86447,"java":146742,"C#":0,"r":7647,"clojure":13881,"objective-c":12415},{"date":"2015-11-01","ruby":112173,"python":73320,"nodejs":206966,"php":90057,"java":151428,"C#":0,"r":7647,"clojure":14143,"objective-c":13097},{"date":"2015-12-01","ruby":113613,"python":75124,"nodejs":216505,"php":93510,"java":155056,"C#":0,"r":7647,"clojure":14389,"objective-c":13889},{"date":"2016-01-01","ruby":114974,"python":76797,"nodejs":228124,"php":96927,"java":158157,"C#":0,"r":7647,"clojure":14642,"objective-c":14597},{"date":"2016-02-01","ruby":116387,"python":78732,"nodejs":240002,"php":101013,"java":162476,"C#":0,"r":8660,"clojure":15000,"objective-c":15508},{"date":"2016-03-01","ruby":117858,"python":80706,"nodejs":253280,"php":104922,"java":167144,"C#":0,"r":8813,"clojure":15290,"objective-c":16276},{"date":"2016-04-01","ruby":119440,"python":82900,"nodejs":266988,"php":109108,"java":171801,"C#":0,"r":9000,"clojure":15613,"objective-c":17183},{"date":"2016-05-01","ruby":120778,"python":85001,"nodejs":281817,"php":113387,"java":175989,"C#":0,"r":9162,"clojure":15908,"objective-c":18230},{"date":"2016-06-01","ruby":122087,"python":86954,"nodejs":294745,"php":117441,"java":180369,"C#":0,"r":9323,"clojure":16194,"objective-c":19205},{"date":"2016-07-01","ruby":123324,"python":88905,"nodejs":306973,"php":121380,"java":183800,"C#":0,"r":9501,"clojure":16439,"objective-c":20175},{"date":"2016-08-01","ruby":124589,"python":91100,"nodejs":318856,"php":125228,"java":186785,"C#":74257,"r":9686,"clojure":16634,"objective-c":21199},{"date":"2016-09-01","ruby":125847,"python":93279,"nodejs":332604,"php":143349,"java":189973,"C#":76671,"r":9881,"clojure":16908,"objective-c":22230},{"date":"2016-10-01","ruby":127092,"python":95441,"nodejs":342377,"php":155432,"java":193173,"C#":78984,"r":10086,"clojure":17150,"objective-c":23042},{"date":"2016-11-01","ruby":128255,"python":97540,"nodejs":359850,"php":191013,"java":197206,"C#":82048,"r":10257,"clojure":17429,"objective-c":23907},{"date":"2016-12-01","ruby":129430,"python":99726,"nodejs":373866,"php":195210,"java":201662,"C#":84650,"r":10437,"clojure":17677,"objective-c":24961}]
;


  if( jQuery("#plot-summary").length ){
    console.log('Going to render summary plot');
    renderSummaryPlot($("#plot-summary"), summaryData);
  }

  if( jQuery("#plot-trends").length ){
    console.log('Going to render trends container');
    renderTrendPlot( $("#plot-trends"), trendData );
  }
});
