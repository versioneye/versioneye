define([require],function(){function e(e){this.selector=e.selector||"body",this.classes=e.classes||"",this.fontSize=e.fontSize||12,this.width=e.width||200,this.dataset=e.dataset||[],this.titleWidth=50,this.bar={maxWidth:150,minWidth:20,height:18},this.icon=e.icon||{path:"/assets/language",height:20}}return e.prototype={titleCellTemplate:function(e){var t=this;return['<img src="'+t.icon.path+"/"+e.toLowerCase()+'.png"',' style = "height:'+t.icon.height+'px;" class = "pull-left"',' title = "'+e+'" />'].join(" ")},render:function(e){var t=this;t.dataset=e;var n=d3.select(t.selector).append("div");n.attr("class",t.classes);var i=n.append("table");i.style({width:function(){return t.width+"px"},"font-size":function(){return t.fontSize+"px"}}).attr("class","table table-hover table-condensed");var r=(i.append("thead"),i.append("tbody")),a=r.selectAll("tr").data(t.dataset).enter().append("tr").style("width",t.width),o=(a.selectAll("td").data(function(e){return[e.title,e.value]}).enter().append("td").attr("class",function(e,t){return 1==t?"plot":"title"}).style("width",function(e,n){return 1==n?t.bar.maxWidth+"px":t.titleWidth+"px"}).html(function(e,n){return 0==n?t.titleCellTemplate(e):""}),d3.scale.linear().domain(d3.extent(t.dataset,function(e){return e.value})).range([t.bar.minWidth,t.bar.maxWidth]));a.selectAll("td.plot").append("div").text(function(e){return e}).style({background:"#197bae",color:"white","font-size":t.fontSize,"text-align":"right",padding:"1px 5px",height:function(){return"18px"},width:function(e){return o(e)+"px"}})},loadAndRender:function(e){var t=this;d3.json(e,function(e,n){return e?(console.error("Can not load data, quit rendering"+e),0):void t.render(n)})}},e});