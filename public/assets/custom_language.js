function reformatDate(dtString, sourceFmt, targetFmt){
  sourceFmt = (typeof b !== 'undefined') ?  sourceFmt : "YYYY-MM-DD";
  targetFmt = (typeof b !== 'undefined') ?  targetFmt : "dddd, Do MMMM";

  return moment(dtString, sourceFmt).format(targetFmt);
};

function renderReleaseGraph(ctx, dt, theLabel){
  console.debug('Rendering release graph - '+ theLabel);

  theLabel = (typeof b !== 'undefined') ?  theLabel : "Releases per day";
  var dateLabels = [];
  var dateValues = [];
    
  dt.forEach(function(item){
    dateLabels.push( [reformatDate(item['date'])]);
    dateValues.push(item['value']);
  });

  var graphData = {
    labels: dateLabels,
    datasets: [{
      type: 'line',
      label: theLabel,
      data: dateValues,
      fill: true,
      backgroundColor: '#fafafa', //color of filled area under the line
      pointBackgroundColor: '#fafafa',
      pointBorderColor: 'steelblue',
      borderWidth: 1, //line thickness
      borderColor: "steelblue" //line color
    }]
  };
  
  var myLineChart = new Chart(ctx, {
      type: 'line',
      data: graphData,
      options: {
        scales: {xAxes: [{display: false}]}
      }
  });
}

jQuery(document).ready(function(){

  var lang = jQuery("#language").data("language");
  var baseURI = document.location.origin;

  if(jQuery("#plot_latest").length){
    console.log("Fetching stats of latest versions");
    jQuery.getJSON(
      baseURI + "/package/latest/timeline30.json?lang=" + lang,
      function(releaseData){
        renderReleaseGraph(jQuery("#plot_latest"), releaseData, "New versions per day");
      });
  }

  if(jQuery("#plot_novel").length){
    console.log("Fetching stats of newest packages");
    jQuery.getJSON(
      baseURI + "/package/novel/timeline30.json?lang=" + lang,
      function(novelData){
        renderReleaseGraph(jQuery("#plot_novel"), novelData, "New packages created per day");
      });
  }

});
