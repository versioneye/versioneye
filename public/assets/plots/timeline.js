define([require], function(require){
  function Timeline(settings){
    this.selector = settings.selector || "#area3";
    this.margin = settings.margin || {top: 20, right: 10, bottom: 30, left: 10};
    this.padding = settings.padding || {top: 5, right: 0, bottom: 0, left: 0};
    this.width = settings.width || 940;
    this.height = settings.height || 300;
    this.dataset = settings.dataset || []
    this.url = settings.url || "/"
    this.xScaler = d3.time.scale().range([0, this.width - (this.margin.left + this.margin.right)]),
    this.yScaler = d3.scale.linear().range([this.height - (this.margin.top + this.margin.bottom), this.padding.top]),
    this.dateParser = d3.time.format("%Y-%m-%d").parse,
    this.bisectDate = d3.bisector(function(d){return d.date;}).left,
    this.strokeScaler = d3.scale.category10();
  };

  Timeline.prototype.loadAndRender = function(url){
    var thisPlot = this;
  	//-- load data & draw plot
    d3.json(url, function(error, data){
      if(error){
        console.error("Can not load for Timeline from url: " + url);
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

  Timeline.prototype.initCanvas = function(){
    var thisPlot = this;
    //initialize canvas
    var timelineCanvas = d3.select(thisPlot.selector).append("svg")
      .attr({
        "width": thisPlot.width,
        "height": thisPlot.height
      });

    timelineCanvas.append("g")
       .attr("tranform", "translate(" + thisPlot.margin.left + "," + thisPlot.margin.top + ")");

    return timelineCanvas;
  };

  Timeline.prototype.addAxisX = function(timelineCanvas){
    var thisPlot = this,
      xAxis = d3.svg.axis()
        .scale(thisPlot.xScaler)
        .orient("bottom");

    //-- add axis
    timelineCanvas.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + (thisPlot.height - (thisPlot.margin.bottom)) + ")")
      .call(xAxis);

    return timelineCanvas;
  };

  Timeline.prototype.addAxisY = function(timelineCanvas){
    var thisPlot = this;
    var yAxis = d3.svg.axis()
      .scale(thisPlot.yScaler)
      .orient("left");

    return timelineCanvas;
  };

  Timeline.prototype.addFocusator = function(timelineCanvas){
    var thisPlot = this;
    var focus = timelineCanvas.append("g")
                  .attr("class", "focus")
                  .style("display", "none");
    focus.append("circle").attr("r", 4.5)
    focus.append("text").attr({"x": 9, "dy": ".35em"});

    //-- info box
    timelineCanvas.append("rect")
          .attr({
            "class": "overlay",
            "width": thisPlot.width + "px",
            "height": thisPlot.height + "px"
        })
          .on("mouseover", function(){focus.style("display", null);})
          .on("mouseout", function(){focus.style("display", "none");})
          .on("mousemove", mousemove);

    function mousemove() {
      var x0 = thisPlot.xScaler.invert(d3.mouse(this)[0]),
          data = thisPlot.dataset,
          i = thisPlot.bisectDate(data, x0, 1),
          d0 = data[i - 1];

      var d1 = (i < data.length) ? data[i] : data[data.length - 1];
      var d = (x0 - d0.date > d1.date - x0) ? d1 : d0;

      focus.attr("transform",
        "translate(" + thisPlot.xScaler(d.date)
        + "," + thisPlot.yScaler(d.value) + ")");
      focus.select("text").text(d.value);
    }
  };

  Timeline.prototype.registerEvents = function(){
    var thisPlot = this;

    d3.selectAll(".lang-timeline-btn").on("click", function(ev){
      var lang = d3.select(this).attr("data-lang"),
          source_url = thisPlot.url + '?lang=' + lang;
      d3.selectAll(".lang-timeline-btn").classed("active", false);
      d3.select(this).classed("active", true);
      d3.select(thisPlot.selector).select("svg").remove();
      thisPlot.loadAndRender(source_url);
    });
  };

  Timeline.prototype.render = function(data){
    var thisPlot = this;
    thisPlot.dataset = data;

    //-- update scalers
    thisPlot.strokeScaler.domain(data.length);
    thisPlot.xScaler.domain(d3.extent(data, function(d){return d.date;}));
    thisPlot.yScaler.domain(d3.extent(data, function(d){return d.value;}));

    //-- render content
    var timelineCanvas = thisPlot.initCanvas();
    var timeline = timelineCanvas.selectAll(".lang")
                      .data(thisPlot.dataset)
                      .enter().append("g")
                        .attr("class", "lang1");
    var plotLine = d3.svg.line()
                      .interpolate("linear")
                      .x(function(d, i){return thisPlot.xScaler(d.date);})
                      .y(function(d, i){return thisPlot.yScaler(d.value);});

    timeline.append("path")
      .style({"stroke": "steelblue"})
      .attr({
        "class": "line",
        "d": function(d){return plotLine(data);}
      });

    thisPlot.addAxisX(timelineCanvas);
    thisPlot.addFocusator(timelineCanvas); //-- add focus element
    thisPlot.registerEvents();
  };

  return Timeline;
});
