
function text_counter(max_size){
	var feedback = jQuery('[name="feedback"]').val();
	jQuery('.feedback-help').text = max_size - feedback.length;
}


function validateEmail(email){
	return true;
}


function load_dialog_feedback(){
	value_a = Math.floor((Math.random()*10)+1);
	value_b = Math.floor((Math.random()*10)+1);
	a_element = document.getElementById("value_a");
	b_element = document.getElementById("value_b");
	fb_math_label = document.getElementById("fb_math");
	a_element.value = value_a;
	b_element.value = value_b;
	fb_math_label.innerHTML = value_a + " + " + value_b + " = ";
	jQuery('#dialog_feedback').modal({keyboard : true});	
}

function validateFeedbackForm(){	
	var result = true
	var fullname = jQuery('[name="fb_fullname"]').val();	
	if (fullname == "" || fullname == null){
		alert('Please type in your Name.')
		result = false
	}
	var email = jQuery('[name="fb_email"]').val();	

	result = validateEmail(email);
	var feedback = jQuery('[name="feedback"]').val();	
	if (feedback == "" || feedback == null){
		alert('Please type in your Feedback.')
		result = false
	}


	if (result == true){
		//hide modal
		jQuery('#dialog_feedback').modal('hide');
	}
	return result;
}