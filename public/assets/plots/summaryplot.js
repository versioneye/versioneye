define([require],function(require){

  function SummaryPlot(settings){
    this.selector = settings.selector || "body";
    this.classes = settings.classes || "";
    this.fontSize =settings.fontSize || 12;
    this.width = settings.width || 200;
    this.dataset =  settings.dataset || [];
    this.titleWidth = 50;
    this.bar = {
      maxWidth: 150,
      minWidth: 20,
      height: 18
    };
    this.icon = settings.icon || {path: '/assets/language', height: 20};
  };

  SummaryPlot.prototype = {
    titleCellTemplate : function(title){
      var thisPlot = this;
      return ['<img src="' + thisPlot.icon.path + '/' + title.toLowerCase() + '.png"',
              ' style = "height:'+ thisPlot.icon.height +'px;" class = "pull-left"',
              ' title = "' + title + '" />'
              ].join(" ");
    },
    render: function(data){
      var thisPlot = this;
      thisPlot.dataset = data;

      var container = d3.select(thisPlot.selector).append("div");
      container.attr("class", thisPlot.classes);

      var datatable = container.append("table");
      datatable
        .style({
          "width": function(){return thisPlot.width + "px";},
          "font-size": function(){return thisPlot.fontSize + "px";}
        })
        .attr("class", "table table-hover table-condensed");

      var table_head = datatable.append("thead");
      var table_body = datatable.append("tbody");

      //-- create datatable
      var rows = table_body.selectAll("tr")
                  .data(thisPlot.dataset)
                  .enter()
                  .append("tr")
                  .style("width", thisPlot.width);

      var cells = rows.selectAll("td")
                    .data(function(row){return [row.title, row.value];})
                    .enter()
                    .append("td")
                    .attr("class", function(d, i){ return i==1 ? "plot": "title";})
                    .style("width", function(d, i){return i==1 ? thisPlot.bar['maxWidth'] + "px": thisPlot.titleWidth + "px";})
                    .html(function(d,i){return i==0 ? thisPlot.titleCellTemplate(d): "";});

      //-- add plot into td.plot
      var barScaler = d3.scale.linear()
                        .domain(d3.extent(thisPlot.dataset, function(d){return d.value;}))
                        .range([thisPlot.bar['minWidth'], thisPlot.bar['maxWidth']]);

      rows.selectAll("td.plot")
          .append("div")
            .text(function(d,i){return d;})
            .style({
              "background": "#197bae",
              "color": "white",
              "font-size": thisPlot.fontSize,
              "text-align": "right",
              "padding": "1px 5px",
              "height": function(d){return 18 + "px";},
              "width": function(d){return barScaler(d) + "px";}
          });
    },
    loadAndRender: function(source_url){
      var thisPlot = this;

      d3.json(source_url, function(error, data){
        if(error){
          console.error("Can not load data, quit rendering" + error);
          return 0;
        }

        thisPlot.render(data);
      });
    }
  }

  return SummaryPlot;
});
