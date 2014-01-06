define([require], function(require){

  function Timebar(settings){
    this.selector = settings.selector || "#area4";
    this.margin   = settings.margin || {top: 0, right: 10, bottom: 0, left: 10};
    this.width    = settings.width || 960;
    this.height   = settings.height || 300;
    this.dataset  = settings.dataset || [];

    var maxHeight = this.height - (this.margin.top + this.margin.bottom);
    this.bar      = {width: 10, maxHeight: maxHeight, padding: 2};
    this.fontSize = settings.fontSize || 11;

    this.xScaler    = d3.time.scale().rangeRound([0, this.width]);
    this.yScaler    = d3.scale.linear().range([this.bar.maxHeight , 0]);
    this.dateParser = d3.time.format("%Y-%m-%d").parse;
    this.bisectDate = d3.bisector(function(d){return d.date;}).left;
  }

  Timebar.prototype.loadAndRender = function(url){
    var thisPlot = this;
    d3.json(url, function(error, data){
      if(error){
        console.error("Can not load data for Timebar from url: " + url);
        return 1;
      }

      //-- preprocess data
      data.forEach(function(d){
        d.value = +d.value;
        d.date = thisPlot.dateParser(d.date);
      });

      data.sort(function(a, b) {
        return a.date - b.date;
      });

      thisPlot.render(data);
    });
  };

  Timebar.prototype.render = function(data){
    var thisPlot = this;
    thisPlot.dataset = data;

    //-- update scalers
    thisPlot.xScaler.domain([new Date(data[0].date), d3.time.day.offset(new Date(data[data.length - 1].date), 1)]);
    thisPlot.yScaler.domain([0, d3.max(data, function(d){return d.value;})]);
    //thisPlot.yScaler.domain(d3.extent(data, function(d){return d.value;}));
    //-- render content
    var timebarCanvas = thisPlot.initCanvas();
    var timebar = timebarCanvas.select("g")

    thisPlot.bar.width = Math.round(thisPlot.width / (thisPlot.dataset.length * 1.0))  - thisPlot.bar.padding;
    timebar.selectAll(".bar")
      .data(thisPlot.dataset)
      .enter()
        .append("rect")
          .attr({
            "class" : "bar",
            "x": function(d){return thisPlot.xScaler(d.date);},
            "width": thisPlot.bar.width,
            "y": function(d){return thisPlot.yScaler(d.value) ;},
            "height": function(d){return thisPlot.bar.maxHeight -  thisPlot.yScaler(d.value) ;}
          });

    timebar.selectAll(".barValues")
      .data(thisPlot.dataset)
      .enter()
      .append("text")
          .attr({
            "x" : function(d){return thisPlot.xScaler(d.date) + thisPlot.bar.width/2.0 ;},
            "y" : function(d){return thisPlot.yScaler(d.value) + thisPlot.fontSize;},
            "fill" : "lightgrey",
            "text-anchor" : "middle"
          })
          .text(function(d){return d.value});

    //-- add axis
    thisPlot.addAxisX(timebarCanvas);
    thisPlot.addTooltip(timebarCanvas);
  };

  Timebar.prototype.initCanvas = function(){
    var thisPlot = this;
    //initialize canvas
    var timebarCanvas = d3.select(thisPlot.selector).append("svg")
      .attr({
        "width": thisPlot.width,
        "height": thisPlot.height
      });

    timebarCanvas.append("g")
       .attr("tranform", "translate(" + thisPlot.margin.left + "," + thisPlot.margin.top + ")");

    return timebarCanvas;
  };

  Timebar.prototype.addTooltip = function(timebarCanvas){
    var tooltip = d3.select("body").append("div")
                    .attr("class", "tooltip")
                    .style("opacity", 0);
    var dateFormatter = d3.time.format("%A, %e.%B");

    d3.selectAll(".bar")
        .on("mouseover", function(d){
          tooltip.transition()
                  .duration(200)
                  .style({
                    "opacity": 0.9,
                    "left": (d3.event.pageX - 10) + "px",
                    "top" : (d3.event.pageY) + "px"
                  })
                  .text(dateFormatter(d.date));
        })
        .on("mouseout", function(d){
          tooltip.transition()
                  .duration(500)
                  .style("opacity", 0);
        });

  };
  Timebar.prototype.addAxisX = function(timebarCanvas){
    var thisPlot = this,
      xAxis = d3.svg.axis()
        .scale(thisPlot.xScaler)
        .ticks(d3.time.mondays, 1)
        .tickFormat(d3.time.format("%d-%m-%y"))
        .orient("bottom");

    //-- add axis
    timebarCanvas.append("g")
      .attr({
        "class": "x axis",
        "transform": "translate(0," + (thisPlot.height - thisPlot.margin.bottom + 5) + ")",
        "fill": "steelblue"
      })
      .call(xAxis);

    return timebarCanvas;
  };

  return Timebar;
});
