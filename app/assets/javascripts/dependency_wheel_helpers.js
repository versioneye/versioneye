
function handle_path(options){
  jQuery.ajax({
        type: 'POST',
        url: "/package/image_path.json",
        data: { 'key': options.product_key, 'version': options.product_version, 'scope': options.scope },
        dataType: 'text',
        success: function(data) {
          if (data == "nil" ){
            // upload_file(options);
          } else {
            show_pinit_button(data, options);
          }
        }
    });
}

function upload_file(options){
  canvas = document.getElementById(options.canvas_id)
  if (canvas && options.pinit){
    jQuery.ajax({
        type: 'POST',
        url: "/package/upload_image.json",
        data: { 'image': document.getElementById(options.canvas_id).toDataURL(),
          'key': options.product_key,
          'version': options.product_version,
          'scope': options.scope },
        dataType: 'text',
        success: function(data) {
            show_pinit_button(data, options);
        }
    });
  }
}

function show_pinit_button(picture_url, options){
  if (options.pinit == false){
    return ;
  }
  if (options.resize == false && options.data_length > options.data_border){
    canvas_container = document.getElementById(options.container_id);
    var img = document.createElement("IMG");
    img.src = picture_url;
    img.style.width = "600px"
    canvas_container.appendChild(img);
  }
  pin_button = document.getElementById("pinit");
  pin_button.href = "https://pinterest.com/pin/create/button/?url=https%3A%2F%2Fwww.versioneye.com/package/"+options.product_key+"/"+options.product_version+"&media="+picture_url+"&description=" + options.product_name + " : " + options.version + " : " + options.scope;
  pin_button.style.display = "block";
}
