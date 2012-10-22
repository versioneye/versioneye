
function validateEmail(elementValue){  
	var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;  
	var result = emailPattern.test(elementValue);  
	if (result == false){
		alert('The E-Mail Address is not valid! Please type in a valid E-Mail Address');
	}
	return result;
}

function textCounter(field, cntfield, maxlimit) {
	if (field.value.length > maxlimit) 
		field.value = field.value.substring(0, maxlimit);
	else
		cntfield.innerHTML = maxlimit - field.value.length;
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
		jQuery('#dialog_feedback').modal('hide');
	}
	return result;

}