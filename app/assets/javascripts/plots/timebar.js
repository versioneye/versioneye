define([require], function(require){
  function Timebar(settings){
    this.selector = settings.selector || "#area4";
    this.margin = settings.margin || {top: 30, right: 10, bottom: 30, left: 10};
    this.width = settings.width || 960;
    this.height = settings.height || 300;
    this.dataset = settings.dataset || [];
    this.bar = settings.bar || {width: 10};

    this.xScaler = d3.time.scale()
      .rangeRound([0, this.width - this.margin.left - this.margin.right]);
    this.yScaler = d3.scale.linear().range([this.height - (this.margin.top + this.margin.bottom), 0]);
    this.dateParser = d3.time.format("%d-%m-%Y").parse;
    this.bisectDate = d3.bisector(function(d){return d.date;}).left;
  }

  Timebar.prototype.loadAndRender = function(url){
    var thisPlot = this;
    d3.json(url, function(error, data){
      if(error){
        console.error("Cant load data for Timebar from url: " + url);
        return 1;
      }

      //-- preprocess data
      data.forEach(function(d){
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
    thisPlot.yScaler.domain(d3.extent(data, function(d){return d.value;}));
    //-- render content
    console.debug(thisPlot.xScaler);
    var timebarCanvas = thisPlot.initCanvas();
    timebarCanvas.selectAll(".bar")
      .data(thisPlot.dataset)
      .enter().append("rect").attr({
        "class" : "bar",
        "x": function(d){return thisPlot.xScaler(d.date);},
        "width": thisPlot.bar.width,
        "y": function(d){return thisPlot.yScaler(d.value);},
        "height": function(d){return (thisPlot.height - thisPlot.margin.bottom) - thisPlot.yScaler(d.value);}
      });

    //-- add axis
    thisPlot.addAxisX(timebarCanvas);
    thisPlot.addFocusator(timebarCanvas);
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
        "transform": "translate(0," + (thisPlot.height - thisPlot.margin.bottom) + ")",
        "fill": "steelblue"
      })
      .call(xAxis);

    return timebarCanvas;
  };

  Timebar.prototype.addFocusator = function(timebarCanvas){
    var thisPlot = this;
    var focus = timebarCanvas.append("g")
                  .attr({
                    "class": "focus",
                    "fill": "blue"
                  })
                  .style("display", "none");

    focus.append("text")
      .style({"font-size": "11"});

    //-- info box
    timebarCanvas
          .on("mouseover", function(ev){focus.style("display", null);})
          .on("mouseout", function(){focus.style("display", "none");})
          .on("mousemove", mousemove);

    function mousemove() {
      var x0 = thisPlot.xScaler.invert(d3.mouse(this)[0]),
          data = thisPlot.dataset,
          i = thisPlot.bisectDate(data, x0, 1),
          d0 = data[i - 1];

      var d1 = (i < data.length) ? data[i] : data[data.length - 1];
      var d = (x0 - d0.date > d1.date - x0) ? d1 : d0;
      var X = thisPlot.xScaler(d.date) - thisPlot.bar.width,
          Y = thisPlot.yScaler(d.value);

      focus.attr("transform", "translate(" + X + "," + Y + ")");
      focus.select("text").text(d.value);
    }
  };
  return Timebar;
});