
function textCounter(field, cntfield, maxlimit) {
  if (field.value.length > maxlimit)
    field.value = field.value.substring(0, maxlimit);
  else
    cntfield.innerHTML = maxlimit - field.value.length;
}

function load_dialog_feedback(){
  if (jQuery('#dialog_feedback').modal){
    jQuery('#dialog_feedback').modal({keyboard : true});
  } else {
    cancel_button = document.getElementById("love_icon");
    cancel_button.click();
  }
}

function validateFeedbackForm(){
  var result = true
  var fullname = jQuery('[name="fb_fullname"]').val();
  if (fullname == "" || fullname == null){
    alert('Please type in your Name.')
    result = false
  }
  var email = jQuery('[name="fb_email"]').val();

  var feedback = jQuery('[name="feedback"]').val();
  if (feedback == "" || feedback == null){
    alert('Please type in your Feedback.')
    result = false
  }

  if (result == true){
    if (jQuery('#dialog_feedback').modal){
      jQuery('#dialog_feedback').modal('hide');
    } else {
      // Fallback solution. Used on API page.
      cancel_button = document.getElementById("feedback_dialog_cancel");
      cancel_button.click();
    }
  }
  return result;
}
