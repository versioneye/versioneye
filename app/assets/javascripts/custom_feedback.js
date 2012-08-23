

function load_dialog_feedback(){
	value_a = Math.floor((Math.random()*10)+1);
	value_b = Math.floor((Math.random()*10)+1);
	a_element = document.getElementById("value_a");
	b_element = document.getElementById("value_b");
	fb_math_label = document.getElementById("fb_math");
	a_element.value = value_a;
	b_element.value = value_b;
	fb_math_label.innerHTML = value_a + " + " + value_b + " = ";
	jQuery('#dialog_feedback').dialog(
		{
		resizable: false, 
		modal: true, 
		draggable: false, 
		minWidth: 700, 
		});	
}

function validateFeedbackForm(){	
	var result = true
	var fullname = document.getElementById('fb_fullname').value;	
	if (fullname == "" || fullname == null){
		alert('Please type in your Name.')
		result = false
	}
	var email = document.getElementById('fb_email').value;	
	result = validateEmail(email)
	var feedback = document.getElementById('feedback').value;	
	if (feedback == "" || feedback == null){
		alert('Please type in your Feedback.')
		result = false
	}
}