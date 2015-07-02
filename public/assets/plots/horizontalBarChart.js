define([require], function(require){
  function HorizontalBarChart(settings){
    this.selector = settings.selector || "body";
    this.height = settings.height || 400;
    this.width = settings.width || 680;
    this.margin = {top: 10, right: 20, bottom: 12, left: 80};
    this.canvasWidth = (this.width - this.margin.left - this.margin.right);
    this.canvasHeight = (this.height - this.margin.top - this.margin.bottom)
    this.fontSize = settings.fontSize || 10;
    this.dataset = settings.dataset || [];
    this.title = settings.title || "";

    this.xScaler = d3.scale.linear()
                      .range([0, this.canvasWidth]);
    this.yScaler = d3.scale.ordinal()
                      .rangeRoundBands([0, this.canvasHeight], 0.2);
  }

  HorizontalBarChart.prototype.loadAndRender = function(url){
    var thisPlot = this;
    d3.json(url, function(error, data){
      if(error){
        console.error("Can not load data from: " + url);
        return 1;
      }
      //preprocess data
      data.forEach(function(d){ d.value = +d.value; });
      data.sort(function(a, b){ return (a.value >= b.value) ? -1 : 1; });

      thisPlot.render(data);
    });
  }

  HorizontalBarChart.prototype.render = function(data){
    var thisPlot = this;
    thisPlot.dataset = data;

    //update scalers
    thisPlot.xScaler.domain([0, d3.max(data, function(d){return d.value;})]);
    thisPlot.yScaler.domain(data.map(function(d){ return d.name; }));

    //render content
    canvas = thisPlot.initCanvas(thisPlot.selector);
    canvas.select("g")
          .selectAll(".bar")
            .data(data)
            .enter()
            .append("rect")
              .attr({
                "class": "bar",
                "x": function(d){ return 0; },
                "y": function(d){ return thisPlot.yScaler(d.name);},
                "width": function(d){ return thisPlot.xScaler(d.value);},
                "height": thisPlot.yScaler.rangeBand()
              });

    thisPlot.addBarLabels();
    thisPlot.addBarTitles();
    thisPlot.addAxisX();
    thisPlot.addTitle(thisPlot.title || "");
  }

  HorizontalBarChart.prototype.initCanvas = function(selector){
    var thisPlot = this;

    var canvas = d3.select(selector)
                    .append("svg")
                      .attr({
                        "width": thisPlot.width,
                        "height": thisPlot.height
                      });
    canvas.append("g")
          .attr("transform", "translate(" + thisPlot.margin.left + "," + thisPlot.margin.top + ")");

    thisPlot.canvas = canvas;
    return canvas;
  }

  HorizontalBarChart.prototype.addBarLabels = function(){
    var thisPlot = this;
    thisPlot.canvas.select("g")
      .selectAll("text")
        .data(thisPlot.dataset)
          .enter()
          .append("text")
            .text(function(d){return d.value})
            .attr({
              "x" : function(d){ return thisPlot.xScaler(d.value) - thisPlot.fontSize * String(d.value).length},
              "y" : function(d){ return thisPlot.yScaler(d.name) + thisPlot.yScaler.rangeBand() / 1.8},
              "fill":  "white"
            });
  }

  HorizontalBarChart.prototype.addBarTitles = function(){
    var thisPlot = this;
    var barTitles = thisPlot.canvas.append("g");
    barTitles
      .attr("transform", "translate(0, " + thisPlot.margin.top + ")")
      .selectAll("text")
        .data(thisPlot.dataset)
          .enter()
          .append("text")
            .text(function(d){return d.name})
            .attr({
              "class": "barTitle",
              "x" : function(d){ return 0;},
              "y" : function(d){ return thisPlot.yScaler(d.name) + thisPlot.yScaler.rangeBand() / 1.8}
        });
  }


  function make_x_axis(thisPlot) {
    return d3.svg.axis()
              .scale(thisPlot.xScaler)
               .orient("bottom")
               .ticks(5);
  }

  HorizontalBarChart.prototype.addAxisX = function(){
    var thisPlot = this;

    thisPlot.canvas.append("g")
        .attr("class", "grid")
        .attr("transform", "translate("+ thisPlot.margin.left + "," + thisPlot.canvasHeight + ")")
        .call(make_x_axis(thisPlot)
            .tickSize(-thisPlot.canvasHeight + thisPlot.margin.top, 0, 0)
            .tickFormat(function(d){return d;})
        )

  }

  HorizontalBarChart.prototype.addTitle = function(title){
    var thisPlot = this;
    thisPlot.canvas.append("g")
      .attr("class", "")
      .append("text")
        .text(title)
        .attr({
          class: "plotTitle",
          x: function(d){return thisPlot.width / 2.0;},
          y: function(d){return thisPlot.margin.top + 5;}
        });
  }

  return HorizontalBarChart;
});
