function reformatDate(dtString, sourceFmt = "YYYY-MM-DD", targetFmt = "dddd, Do MMMM"){
  return moment(dtString, sourceFmt).format(targetFmt);
};

function renderReleaseGraph(ctx, dt, theLabel = "Releases per day"){
  console.debug('Rendering release graph - '+ theLabel);
  
 
  var dateLabels = _.reduce(dt, function(acc, item){
    acc.push([reformatDate(item['date'])]);
    return acc;
  }, []);

  var dataValues = _.reduce(dt, function(acc, item){
    acc.push(item['value']);
    return acc;
  }, []);

  var graphData = {
    labels: dateLabels,
    datasets: [{
      type: 'line',
      label: theLabel,
      data: dataValues,
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
  var releaseData = [{"title":"Python","value":410,"date":"2016-12-19"},{"title":"Python","value":632,"date":"2016-12-20"},{"title":"Python","value":648,"date":"2016-12-21"},{"title":"Python","value":676,"date":"2016-12-22"},{"title":"Python","value":578,"date":"2016-12-23"},{"title":"Python","value":481,"date":"2016-12-24"},{"title":"Python","value":235,"date":"2016-12-25"},{"title":"Python","value":194,"date":"2016-12-26"},{"title":"Python","value":345,"date":"2016-12-27"},{"title":"Python","value":433,"date":"2016-12-28"},{"title":"Python","value":510,"date":"2016-12-29"},{"title":"Python","value":537,"date":"2016-12-30"},{"title":"Python","value":551,"date":"2016-12-31"},{"title":"Python","value":235,"date":"2017-01-01"},{"title":"Python","value":316,"date":"2017-01-02"},{"title":"Python","value":535,"date":"2017-01-03"},{"title":"Python","value":586,"date":"2017-01-04"},{"title":"Python","value":589,"date":"2017-01-05"},{"title":"Python","value":624,"date":"2017-01-06"},{"title":"Python","value":607,"date":"2017-01-07"},{"title":"Python","value":357,"date":"2017-01-08"},{"title":"Python","value":390,"date":"2017-01-09"},{"title":"Python","value":668,"date":"2017-01-10"},{"title":"Python","value":781,"date":"2017-01-11"},{"title":"Python","value":713,"date":"2017-01-12"},{"title":"Python","value":756,"date":"2017-01-13"},{"title":"Python","value":732,"date":"2017-01-14"},{"title":"Python","value":390,"date":"2017-01-15"},{"title":"Python","value":467,"date":"2017-01-16"},{"title":"Python","value":678,"date":"2017-01-17"}];


  var novelData = [{"title":"Python","value":60,"date":"2016-12-19"},{"title":"Python","value":106,"date":"2016-12-20"},{"title":"Python","value":128,"date":"2016-12-21"},{"title":"Python","value":155,"date":"2016-12-22"},{"title":"Python","value":123,"date":"2016-12-23"},{"title":"Python","value":89,"date":"2016-12-24"},{"title":"Python","value":56,"date":"2016-12-25"},{"title":"Python","value":47,"date":"2016-12-26"},{"title":"Python","value":95,"date":"2016-12-27"},{"title":"Python","value":128,"date":"2016-12-28"},{"title":"Python","value":125,"date":"2016-12-29"},{"title":"Python","value":100,"date":"2016-12-30"},{"title":"Python","value":130,"date":"2016-12-31"},{"title":"Python","value":47,"date":"2017-01-01"},{"title":"Python","value":67,"date":"2017-01-02"},{"title":"Python","value":105,"date":"2017-01-03"},{"title":"Python","value":125,"date":"2017-01-04"},{"title":"Python","value":90,"date":"2017-01-05"},{"title":"Python","value":131,"date":"2017-01-06"},{"title":"Python","value":117,"date":"2017-01-07"},{"title":"Python","value":56,"date":"2017-01-08"},{"title":"Python","value":113,"date":"2017-01-09"},{"title":"Python","value":134,"date":"2017-01-10"},{"title":"Python","value":175,"date":"2017-01-11"},{"title":"Python","value":149,"date":"2017-01-12"},{"title":"Python","value":134,"date":"2017-01-13"},{"title":"Python","value":150,"date":"2017-01-14"},{"title":"Python","value":112,"date":"2017-01-15"},{"title":"Python","value":79,"date":"2017-01-16"},{"title":"Python","value":142,"date":"2017-01-17"}]


  if(jQuery("#plot_latest").length){
    renderReleaseGraph(jQuery("#plot_latest"), releaseData, "New versions per day");
  }

  if(jQuery("#plot_novel").length){
    renderReleaseGraph(jQuery("#plot_novel"), novelData, "New packages created per day");
  }

});
