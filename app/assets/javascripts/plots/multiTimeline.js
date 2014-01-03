define([require], function(require){
  function MultiTimeline(settings){
    this.selector = settings.selector || "#area2";
    this.legend = {}
    this.legend.selector = settings.legend.selector;
    this.margin = settings.margin || {top: 20, right: 20, bottom: 20, left: 80};
    this.width = settings.width || 960;
    this.height = settings.height || 400;
    this.canvasWidth = this.width - this.margin.left - this.margin.right;
    this.canvasHeight = this.height - this.margin.top - this.margin.bottom;

    this.dateFormat = "%Y-%m-%d";
    this.title = settings.title || "";
    this.dataset = settings.dataset || [];

    this.colorScaler = d3.scale.category10();
    this.xScaler = d3.time.scale().range([0, this.canvasWidth]);
    this.yScaler = d3.scale.linear().range([
      this.canvasHeight, 0
    ]);
    this.dateParser = d3.time.format(this.dateFormat).parse;
    this.bisectDate = d3.bisector(function(d){return d.date;}).left,
    this.liner = d3.svg.line()
                  .interpolate("basis")
                  .x(function(d){ return this.xScaler(d.date);})
                  .y(function(d){ return this.yScaler(d.value);})
  }

  MultiTimeline.prototype.loadAndRender = function(url){
    var thisPlot = this;
    d3.json(url, function(error, data){
      if(error){
        console.error("Can not load data from url: " + url);
        return 1;
      }
      //-- preprocess data
      data.forEach(function(d){
        d.date = thisPlot.dateParser(d.date);
      });
      data.sort(function(a, b){
        return a.date - b.date;
      });

      thisPlot.render(data);
    });
  }

  MultiTimeline.prototype.render = function(data){
    var thisPlot = this;
    this.colorScaler.domain(d3.keys(data[0]).filter(
      function(key){return key !== "date";}
    ));
    thisPlot.data = data; //original dataset
    thisPlot.dataset = this.colorScaler.domain().map(function(name){
      return {
        name: name,
        values: data.map(function(d){
          return {date: d.date, value: +d[name]}
        })
      }
    });

    thisPlot.xScaler.domain(d3.extent(data, function(d){return d.date;}));
    thisPlot.yScaler.domain([
      d3.min(thisPlot.dataset, function(d){
        return d3.min(d.values, function(v){return v.value;});
      }),
      d3.max(thisPlot.dataset, function(d){
        return d3.max(d.values, function(v){return v.value;});
      })
    ]);

    canvas = thisPlot.initCanvas().select(".canvas");
    var timeline = canvas.selectAll(".timeline")
                    .data(thisPlot.dataset)
                    .enter()
                    .append("g")
                      .attr("class", "timeline");
    timeline.append("path")
            .attr({
              "class": "line",
              "id": function(d){return "line_" + d.name ;},
              "d": function(d){ return thisPlot.liner(d.values);}
            })
            .style({
              "opacity": 0.3,
              "stroke": function(d){return thisPlot.colorScaler(d.name);}
            });

    thisPlot.addAxisX();
    thisPlot.addAxisY();
    thisPlot.addTitle();
    thisPlot.addLegend();
    //thisPlot.addFocusator();
  }

  MultiTimeline.prototype.initCanvas = function(){
    var thisPlot = this;
    var canvas = d3.select(thisPlot.selector).append("svg")
                    .attr({
                      "width": thisPlot.width,
                      "height": thisPlot.height
                    });
    canvas.append("g")
      .attr("class", "canvas")
      .attr("transform", "translate(" + thisPlot.margin.left + "," + thisPlot.margin.top + ")");

    thisPlot.canvas = canvas;
    return canvas;
  }

  MultiTimeline.prototype.addAxisX = function(){
    var thisPlot = this;
    var xAxis = d3.svg.axis()
                  .scale(thisPlot.xScaler)
                  .orient("bottom")
                  .ticks(thisPlot.dataset.length, 3);
                  //.tickFormat(d3.time.format("%b/%y"));
                  //.attr("transform", "rotate(-45)");
    thisPlot.canvas.append("g")
      .attr({
        "class": "x axis",
        "transform": "translate(" + thisPlot.margin.left + "," + (thisPlot.height - thisPlot.margin.bottom) + ")"
      })
      .call(xAxis);
  }

  MultiTimeline.prototype.addAxisY = function(){
    var thisPlot = this;
    var yAxis = d3.svg.axis()
                  .scale(thisPlot.yScaler)
                  .orient("left")
                  .ticks(5);

    thisPlot.canvas.append("g")
      .attr("class", "y axis")
      .attr("transform", "translate(" + thisPlot.margin.left + "," + thisPlot.margin.top + ")")
      .call(yAxis);
  }

  MultiTimeline.prototype.addTitle = function(){
    var thisPlot = this;
    thisPlot.canvas.append("g")
      .attr("class", "")
      .append("text")
        .text(thisPlot.title)
        .attr({
          class: "plotTitle",
          x: function(d){return thisPlot.width / 2.0;},
          y: function(d){return thisPlot.margin.top;}
        });
  }

  MultiTimeline.prototype.addFocusator = function(){
    var thisPlot = this;
    var toolTip = d3.select("body").append("div")
                  .attr("id", "focusator-tooltip")
                  .attr("class", "nav nav-list tooltip")
                  .style({position: "absolute"})
                  .html("test");

    var focus = thisPlot.canvas.append("g")
                  .attr("class", "focus")
                  .style("display", "none");
    //focus.append("circle").attr("r", 4.5)
    focus.append("text").attr({"x": 9, "dy": ".35em"});

    //-- info box
    thisPlot.canvas.append("rect")
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
          y0 = thisPlot.yScaler.invert(d3.mouse(this)[1])
          data = thisPlot.data,
          i = thisPlot.bisectDate(data, x0, 1),
          d0 = data[i - 1];

      var d1 = (i < data.length) ? data[i] : data[data.length - 1];
      var d = (x0 - d0.date > d1.date - x0) ? d1 : d0;

      console.debug(d);
      formatHTML = "";
      d3.map(d).forEach(function(lang, val){
        formatHTML += '<li>' + lang + ":" + val + '</li>';
      });

      focus.attr("transform", "translate(" + d3.mouse(this)[0] + "," + d3.mouse(this)[1] + ")");
      d3.select("#focusator-tooltip")
        .style({
          "opacity" : 0.9,
          "left": (d3.event.pageX) + 'px',
          "top": (d3.event.pageY) + 'px'
        })
        .html('<ul>' + formatHTML + '</ul>');
    }
  };

  MultiTimeline.prototype.addLegend = function(){
    var thisPlot = this;

    d3.select(thisPlot.legend.selector)
      .append("ul")
        .attr("class", "nav nav-pills")
        .style({"padding-left": thisPlot.margin.left + "px"})
        .selectAll(".btn-legend")
          .data(thisPlot.dataset)
          .enter()
          .append("li")
            .attr({
              "class": "btn-legend",
              "data-language": function(d){d.name;}
            })
            .html(function(d){
              if(d.name != "date"){
                var legendItemHTML = "";
                var color = thisPlot.colorScaler(d.name);
                legendItemHTML = [
                  '<a href = "#">',
                    '<i class = "icon-stop" style = "color: ', color , ' ;">&nbsp;</i>',
                     "&nbsp;", d.name,
                  '</a>'
                ].join('');
              } else {
                console.debug("MultiTimeline legend skips: " + d.name);
              }
              return legendItemHTML;
            })
            .on("mouseover", function(d){
              var line_selector = '#line_' + d.name;
              d3.select(line_selector).style("opacity", 0.9);
            })
            .on("mouseout", function(d){
              console.log("OFF:" + d.name)
              var line_selector = '#line_' + d.name;
              d3.select(line_selector).style("opacity", 0.3);
            });
  }
  return MultiTimeline;
});
