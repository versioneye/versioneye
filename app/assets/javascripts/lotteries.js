function toggle_submit_button(){
  console.debug("user toggled lottery button");
  if( $(".lottery-btn.active").length >= 2){
    console.log("Showing submit button");
    $(".lottery-submit-btn").removeClass('hide');
  } else {
    $(".lottery-submit-btn").addClass('hide');
  }
  return false;
}

$(document).ready(function(){
  $('.btn-group').button();

  $('.lottery-btn').on('click', function(ev){
    toggle_submit_button();
  });
});