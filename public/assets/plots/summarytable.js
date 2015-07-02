define([require], function(require){
  function SummaryTable(settings){
    this.caption = settings.caption || ""
    this.selector = settings.selector || "body";
    this.classes = settings.classes || ""
    this.width = settings.width || 200;
    this.fontSize = settings.fontSize || 12;
    this.titleWidth = settings.titleWidth || 100;
    this.bar = settings.bar || {maxWidth: 100};
    this.dataset = settings.dataset || [];
    this.icon = settings.icon || {path: '/assets/language', height: 20};

    var thisPlot = this;
    this.templates = {
      titleCell: function(title){
        return [
          '<img src="' + thisPlot.icon.path + '/' + title.toLowerCase() + '.png"',
          ' style = "height:'+ thisPlot.icon.height +'px;" class = "pull-left"',
          ' title = "' + title + '" />',
          '<strong>' + title + '</strong>'
        ].join(" ");
      },
      valueCell: function(value){
        return [
          '<small style="text-align: center;">' + value + '</small>'
        ].join(' ');
      },
      caretCell: function(t1){
        var is_pos = parseInt(t1) >= 0;
        return ['<i class = "icon-caret-', (is_pos) ? "up": "down", '" style = "color:',
                (is_pos) ? "green" : "red",
                ';"></i>'
              ].join('');
      }
    } //end-of-templates
  };

  SummaryTable.prototype.render = function(data){
    var thisPlot = this;
    thisPlot.dataset = data;

    var container = d3.select(thisPlot.selector).append("div");
    container
      .attr({"class": thisPlot.classes})
      .html('<h5>' + thisPlot.caption + '</h5>');

    var datatable = container.append("table");
    datatable.style({
      "width": function(){return thisPlot.width + "px";},
      "font-size": function(){return thisPlot.fontSize + "px";}
    })
    .attr("class", "table table-hover table-condensed");
    //-- create datatable
    var table_head = datatable.append("thead");
    var table_body = datatable.append("tbody");
    var rows = table_body.selectAll("tr")
                .data(thisPlot.dataset)
                .enter()
                .append("tr")
                .style("width", thisPlot.width);

    var cells = rows.selectAll("td")
                  .data(function(row){return [row.title, row.value, row.t1];})
                  .enter()
                  .append("td")
                  .attr("class", function(d, i){ return i==1 ? "value": "title";})
                  .html(function(d,i){
                      switch(i){
                        case 0:
                          return thisPlot.templates.titleCell(d);
                          break;
                        case 1:
                          return thisPlot.templates.valueCell(d);
                          break;
                        case 2:
                          return thisPlot.templates.caretCell(d);
                          break;
                      }
                    });
  }

  SummaryTable.prototype.loadAndRender = function(url, settings){
    var thisPlot = this;
    d3.json(url, function(error, data){
      if(error){
        console.error("Can not load data from " + url + "for SummaryTable");
        console.error(error);
        return 1;
      }

      thisPlot.render(data);
    });
  };

  return SummaryTable;
});
