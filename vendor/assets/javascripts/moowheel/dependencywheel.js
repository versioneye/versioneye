/*
    Class: DependencyWheel
    Version: 0.1
    License: MIT
    Author: Robert Reiz (VersionEye GmbH)

    This is a fork from the MooWheel Class version 0.2 from unwieldy studios. 
    Written by Augusto Becciu (http://www.tweetwheel.com)
   
    This fork is customized to visualize dependencies for software libraries. 
    It is used on https://www.versioneye.com
*/

var DependencyWheel = new Class({
    options: {
      type: 'default',
      center: {
         x: 100,
         y: 100
      },
      width: null,
      height: null,
      lines: {
         color: 'random',
         lineWidth: 2
      },
      imageSize: [24,24],
      radialMultiplier: 3.47,
      hover: true,
      hoverLines: {
         color: 'rgba(255,255,255,255)',
         lineWidth: 5
      },
      onItemClick: $empty,
      infoBox: 'mooinfo', 
      infoNumber: 'moonumber', 
      data_border: 70,
      canvas_id: 'canvas', 
      canvas_hover_id: 'canvas_hover', 
      product_key: "product_key", 
      product_version: "product_version", 
      product_name: "product_name", 
      version: "version", 
      show_label: false, 
      resize: false,
      resize_ids: "container,section", 
      resize_factor: 11, 
      scope: "compile", 
      container_id: "canvas-container"
    },
   
    initialize: function(data, ct, options) {
      this.data = data;
      data_length = data.length;
      this.radius = Math.round(this.options.radialMultiplier * data_length);
      this.setOptions(options);

      if (data_length < 3){
        options.height = "77";
        this.options.height = "77";
        options.show_label = false;
        this.options.show_label = false;
      }

      border = this.options.data_border;
      if (data_length > border && this.options.resize == false ){
        show_info_box(data, options);
        return false;
      }
      
      // calculate canvas height/width if necessary
      var hw;
      if (!(this.options.width && this.options.height)) {
        var length = 0;
        for (var i = 0; i < data.length; i++) {
          if (data[i]['text'].length > length)
            length = data[i]['text'].length;
        }
        hw = 2 * ((this.radius + (length * 8)) + this.options.imageSize[0]) + 12;
      }
      
      ct.empty();      
      ct = $(ct);
      var canvas = new Element('canvas', {
        width:  (this.options.width ? this.options.width : hw) + 'px',
        height: (this.options.height ? this.options.height : hw) + 'px',
        id: this.options.canvas_id
      });
      ct.adopt(canvas);
      
      if ( typeof (G_vmlCanvasManager) != 'undefined') {
        canvas = $(G_vmlCanvasManager.initElement(canvas));
      }

      this.canvas = canvas;

      this.cx = canvas.getContext('2d');
      this.maxCount = 1;

      var canvasPos = this.canvas.getCoordinates();
      
      this.options.center = {x: canvasPos.width / 2, y: canvasPos.height / 2};
 
      CanvasTextFunctions.enable(this.cx);

      if (data_length == 0){
        this.cx.fillStyle = "green";
        this.cx.font = "42px Arial";
        this.cx.fillText("0", this.options.center.x - 10, 45);
        show_info_box(this.data, this.options);
        return ;
      }
            
      if(this.options.hover) {
         this.hoverCanvas = new Element('canvas', {
            'styles': {
               position: 'absolute',
               left: canvasPos.left + 'px',
               top:  canvasPos.top + 'px',
               zIndex: 9
            },
            id: this.options.canvas_hover_id,
            width: canvasPos.width + 'px',
            height: canvasPos.height + 'px'
         });
        
         this.hoverCanvas.injectAfter(this.canvas);

         window.addEvent('resize', function() {
            var canvasPos = this.canvas.getCoordinates();
            
            this.hoverCanvas.setStyles({left: canvasPos.left + 'px', top: canvasPos.top + 'px'});
            this.hoverCanvas.width = canvasPos.width;
            this.hoverCanvas.height = canvasPos.height;
         }.bind(this));
  
         if (typeof(G_vmlCanvasManager) != 'undefined') {
             this.hoverCanvas = $(G_vmlCanvasManager.initElement(this.hoverCanvas));
         }
      }
      
      this.data.each(function(item) {
        item['connections'].each(function(subitem) {
            if ($type(subitem) == 'array' && subitem[1] > this.maxCount)
              this.maxCount = subitem[1];
        }, this);
      }, this);
         
      this.draw();
    },
   
   // define each point on the wheel, including it's position and color
   setPoints: function() {
      this.points = {};
      this.bboxes = [];
      
      this.numDegrees = (360 / this.data.length);
      
      for (var i = 0, j = 0; j < this.data.length; i += this.numDegrees, j++) {
         if (this.data[j]['colors']) continue;

         var item = this.data[j];
         var color = {};
         
         if (this.options.lines.color == 'random'){
            p1 = 100;
            p2 = 20;
            color['__default'] = "rgba(" + (Math.floor(Math.random() * p1) + p2) + "," + (Math.floor(Math.random() * p1) + p2) + "," + (Math.floor(Math.random() * p1) + p2) + ", 1)";
         } else{
            color['__default'] = this.options.lines.color;
         }
         this.data[j]['colors'] = color;
      }
   },

   pc: function(x) {
      return Math.round(x/7) * 7;
   },

   // calculate the bounding box of particular text
   calcbbox: function(px, py, i, j) {
      px = Number(px.toFixed(2));
      py = Number(py.toFixed(2));
      i = Number(i.toFixed(2));

      // calculate hover bounding box
      var xc = this.options.center.x, yc = this.options.center.y;

      var m0 = (py - yc) / (px - xc);

      var pr3 = {
        x: px - Math.cos((i+90)*(Math.PI/180))*5,
        y: py - Math.sin((i+90)*(Math.PI/180))*5
      };
      var b3 = pr3.y - m0 * pr3.x;
      var dr3;
      if (m0 == Infinity || m0 == -Infinity)
        dr3 = function(x,y) { return Math.abs((x - pr3.x)); };
      else
        dr3 = function(x,y) { return Math.abs(m0 * x - y + b3) / Math.sqrt(Math.pow(m0,2) + 1); };

      var txtlen = this.cx.measureText('sans','10',this.data[j]['text']);
      txtlen = Number(txtlen.toFixed(2));

      var pr4 = {
        x: px + Math.cos((i + 90) * (Math.PI / 180)) * 5,
        y: py + Math.sin((i + 90) * (Math.PI / 180)) * 5
      };
      var b4 = pr4.y - m0*pr4.x;
      var dr4;
      if (m0 == Infinity || m0 == -Infinity)
        dr4 = function(x,y) { return Math.abs((x-pr4.x)); };
      else
        dr4 = function(x,y) { return Math.abs(m0*x-y+b4)/Math.sqrt(Math.pow(m0,2)+1); };


      this.bboxes[j] = function(x,y) {

        if (i == 0 && (x-px) < 0)
          return false;
        else if (i > 0 && i < 90 && (x-px) < 0 && (y-py) < 0)
          return false;
        else if (i == 90 && (y-py) < 0)
          return false;
        else if (i > 90 && i < 180 && (x-px) > 0 && (y-py) < 0)
          return false;
        else if (i == 180 && (x-px) > 0)
          return false;
        else if (i > 180 && i < 270 && (x-px) > 0 && (y-py) > 0)
          return false;
        else if (i == 270 && (y-py) > 0)
          return false;
        else if (i > 270 && i < 360 && (x-px) < 0 && (y-py) > 0)
          return false;
              

        var d = Math.sqrt(Math.pow((x-px),2) + Math.pow((y-py),2));
        var d3 = dr3(x,y), d4 = dr4(x,y);

        if (d <= (txtlen+8) && d3 <= 10 && d4 <= 10)
          return true;

        return false;
      };
   },
   
   // draw the points onto the canvas
   drawPoints: function() {
      for(var i = 0, j = 0; j < this.data.length; i += this.numDegrees, j++) {
            this.cx.beginPath();
            this.cx.fillStyle = this.cx.strokeStyle = this.data[j]['colors']['__default'];
            
            // solve for the dot location on the large circle
            var x = this.options.center.x + Math.cos(i * (Math.PI / 180)) * this.radius;
            var y = this.options.center.y + Math.sin(i * (Math.PI / 180)) * this.radius;
                                 
            // draw the colored dot
            this.cx.arc(x, y, 4, 0, Math.PI * 2, 0);
            this.cx.fill();
            this.cx.closePath();
          
            this.calcbbox(x, y, i, j); 

            if(!this.points[this.pc(x)])
               this.points[this.pc(x)] = {};
               
            this.points[this.pc(x)][this.pc(y)] = j;

            // draw the text
            this.cx.save();
            this.cx.translate(this.options.center.x, this.options.center.y);
            this.cx.rotate((i > 90 && i < 270 ? i-180 : i) * (Math.PI / 180));

            var txtSlice, imgSlice;
            if (i > 90 && i < 270) {
              txtSlice = -(this.radius + this.cx.measureText('sans','10',this.data[j]['text']+'') + 8);
              imgSlice = txtSlice - 30;
            } else {
              txtSlice = this.radius + 8;
              imgSlice = txtSlice+6+this.cx.measureText('sans','10',this.data[j]['text']+'');
            }

            this.cx.drawText('sans','10', txtSlice, this.cx.fontAscent('sans','10')/2,
                this.data[j]['text']);

            if (this.data[j]['image'])
              this.cx.drawImage($(this.data[j]['image']), imgSlice, -12, this.options.imageSize[0],
                  this.options.imageSize[1]);

            this.cx.restore();
      }
   },

   // calculate a radian angle
   getAngle: function(idx) {
     return idx * (360 / this.data.length);
   },
   
   getItemIdxById: function(id) {
     if($type(id) == 'array') id = id[0];
     
     for (var i = 0, l = this.data.length; i < l; i++)
      if (this.data[i]['id'] == id)
         return i;
  
     return -1;
   },
   
   // draw the connection lines for a particular item
   drawConnection: function(i, hover) {
      if (hover){
        // BugFix for overlay bug in Safari & Chrome
        document.getElementById(this.options.canvas_hover_id).style.top = document.getElementById(this.options.canvas_id).getCoordinates().top + "px";
      }
      var cx = hover ? this.hoverCanvas.getContext('2d') : this.cx;
      var item = this.data[i];
      var connections = item['connections'];
      var angle = this.getAngle(i);
      
      // solve for the line starting point location on the large circle
      var x = this.options.center.x + Math.cos(angle * (Math.PI / 180)) * this.radius;
      var y = this.options.center.y + Math.sin(angle * (Math.PI / 180)) * this.radius;
      
      cx.lineWidth = hover ? this.options.hoverLines.lineWidth : 2;

      // draw the bezier curve
      // note: the control points of the curve are the radius / 2
      for(var j = 0; j < connections.length; j++) {
         var itemIdx = this.getItemIdxById(connections[j]);

         cx.strokeStyle = hover ? (item['colors'][connections[j][0]] ? item['colors'][connections[j][0]] : item['colors']["__default"]).replace(/, \d\.?\d+?\)/, ',1)') :
                                  (item['colors'][connections[j][0]] ? item['colors'][connections[j][0]] : item['colors']["__default"]);

         cx.beginPath();
         cx.moveTo(x, y);
         rpos = this.getAngle(itemIdx);
         x2 = this.options.center.x + Math.cos(rpos * (Math.PI / 180)) * this.radius;
         y2 = this.options.center.y + Math.sin(rpos * (Math.PI / 180)) * this.radius;
         cp1x = this.options.center.x + Math.cos(angle * (Math.PI / 180)) * (this.radius / 1.5);
         cp1y = this.options.center.y + Math.sin(angle * (Math.PI / 180)) * (this.radius / 1.5);
         cp2x = this.options.center.x + Math.cos(rpos * (Math.PI / 180)) * (this.radius / 1.5);
         cp2y = this.options.center.y + Math.sin(rpos * (Math.PI / 180)) * (this.radius / 1.5);
         cx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
         cx.stroke();
         cx.closePath();
      }
      
      if (hover) {
        return;
      }
      
      if (this.data[i+1]) {
         var self = this;
         setTimeout(function() { self.drawConnection(i+1); }, 25);
      } else {
        this.drawPoints();
        if (this.options.show_label){
          cx.fillStyle = "lightgray";
          cx.font = "14px Arial";
          cx.fillText("www.VersionEye.com", this.options.center.x - 70, 30);
        }
        show_info_box(this.data, this.options);
      }
   },
   
   // draw the entire DependencyWheel
   draw: function() {
      if (this.data) {
        this.setPoints();
        this.drawConnection(0);
      }

      if (this.options.hover) {
         $(this.hoverCanvas).addEvent('mousemove', function(e) {
            e = new Event(e);
            
            var pos = $(this.hoverCanvas).getCoordinates();
           
            // convert page coordinates to canvas coordinates 
            var mpos = {x: (e.page.x - pos.left),
                        y: (e.page.y - pos.top)};

            var test = function(point) {
               var cpoint = {x:this.pc(point.x), y:this.pc(point.y)};

               if ($defined(this.points[cpoint.x]) && $defined(this.points[cpoint.x][cpoint.y]))
                  return this.points[cpoint.x][cpoint.y];

               for (var i = 0, l = this.bboxes.length; i < l; i++) {
                  var bbox = this.bboxes[i];
                  if (bbox(point.x,point.y) === true)
                    return i;
               }

               return false;

            }.bind(this);
            
            var conn = test(mpos);
            if(conn !== false) {
               if(this.lastMouseOver == conn)
                  return;
                   
               this.drawConnection(conn, true);

               this.lastMouseOver = conn;

               this.canvas.setStyle('opacity', '0.5');
               this.hoverCanvas.setStyle('cursor', 'pointer');
            } else if ($defined(this.lastMouseOver)) {
               var cx = this.hoverCanvas.getContext('2d');
               cx.clearRect(0, 0, pos.width, pos.height);
               cx.save();
   
               this.lastMouseOver = null;
               
               this.canvas.setStyle('opacity', '1.0'); 
               this.hoverCanvas.setStyle('cursor', 'default');
            }
         }.bind(this));

         $(this.hoverCanvas).addEvent('click', function(e) {
            // if (!this.lastMouseOver) return false;
            this.options.onItemClick(this.data[this.lastMouseOver], e);
         }.bind(this));
      }
   },
   
   // get the brightness/color of a particular line when heat/cold maps are used
   getTemperature: function(type, percent) {
      if(type == 'heat') {
         var p = {r: percent / 0.33, y: (percent - 0.33) / 0.33, w: (percent - 0.66) / 0.66};
   
         var r = Math.round(p.r * 255 > 255 ? 255 : p.r * 255);
         var y = Math.round(p.y * 255 > 255 ? 255 : p.y * 255);
         var w = Math.round(p.w * 255 > 255 ? 255 : p.w * 255);
         
         return 'rgba(' + (r < 0 ? 0 : r) + ',' + (y < 0 ? 0 : y) + ',' + (w < 0 ? 0 : w) + ', ' + (percent * 0.8 + 0.2) + ')';
      } else if(type == 'cold') {         
         var r = Math.round(percent * 255);
         var g = Math.round(130 + (percent * 125));
         
         return 'rgba(' + r + ',' + g + ',255, ' + (percent * 0.8 + 0.2) + ')';
      }
   }
});
DependencyWheel.implement(new Options);

// helper class for AJAX/JSON-based wheel information retrieval
DependencyWheel.Remote = new Class({
    
    Extends: DependencyWheel,

    initialize: function(data, ct, options) {
        var preloadImages = function(wheelData) {
            var imageUrls = [], map = {};
            
            if (!wheelData){
              return false;
            }

            border = options.data_border;
            if (wheelData.length > border && options.resize == true){
              options.width = wheelData.length * options.resize_factor;
              options.height = wheelData.length * options.resize_factor;
              element_ids = options.resize_ids.split(",");
              for (z = 0; z < element_ids.length; z++){
                element = document.getElementById(element_ids[z]);
                new_width = options.width + (z * 20);
                element.style.width = new_width + "px";
              }
            }
            
            for (var i = 0, l = wheelData.length; i < l; i++) {
                if (wheelData[i]['imageUrl']) {
                    imageUrls.push(wheelData[i]['imageUrl']);
                    map[i] = imageUrls.length - 1;
                }
            }

            if (imageUrls.length == 0)
                return false;

            var images = new Asset.images(imageUrls, {
                onComplete: function() {
                    for (var j in map) {
                        wheelData[j]['image'] = images[map[j]];
                    }

                    // hack to make this.parent work within callback
                    arguments.callee._parent_ = this.initialize._parent_;
                    
                    this.parent(wheelData, ct, options);
                }.bind(this)
            });

            return true;
        }.bind(this);

        if (options && options.url) {

            // Get token and param from the meta tags
            // var token = jQuery('meta[name="csrf-token"]').attr('content');
            // var param = jQuery('meta[name="csrf-param"]').attr('content');
            json_url = options.url; // + "?_method=POST&" + param + "=" + token;

            new Request.JSON({
              url: json_url,
              onComplete: function(wheelData) {
                  data = wheelData;

                  // hack to make this.parent work within callback
                  arguments.callee._parent_ = this.initialize._parent_;

                  if (!preloadImages(data, ct, options))
                      this.parent(data, ct, options);
              
              }.bind(this)
            }).send();
        } else if (!preloadImages(data, ct, options)) {
          this.parent(data, ct, options);
        }
    }
});

function show_info_box(data, options){
  box_name = options.infoBox;
  number_name = options.infoNumber;
  recursive_deps = data.length;
  options.data_length = data.length;
  info_box = document.getElementById(box_name);
  info_number = document.getElementById(number_name);
  if (info_box){
    info_box.style.display = "block";
  }
  if (info_number){
    var txt = document.createTextNode(recursive_deps);
    info_number.appendChild(txt); 
  }
  handle_path(options);
}