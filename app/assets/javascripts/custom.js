
$(document).ready(function() {
	
});


function load_dialog_follow(product_name, product_key){
	document.getElementById('dialog_follow_success').style.display = 'none'
	document.getElementById('dialog_follow_form').style.display = 'block'
	document.getElementById('product_to_follow').innerHTML = product_name;
	document.getElementById('product_name_hidden').value = product_name;
	document.getElementById('product_key_hidden').value = product_key;
	$('#dialog_follow').dialog(
		{
		resizable: false, 
		modal: true, 
		draggable: false, 
		minWidth: 600, 
		});	
}

function validateEmail(elementValue){  
	var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;  
	var result = emailPattern.test(elementValue);  
	if (result == false){
		alert('The E-Mail Address is not valid! Please type in a valid E-Mail Address');
	}
	return result;
}