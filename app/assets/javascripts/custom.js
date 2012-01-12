
$(document).ready(function() {
	
	$('#q').tbHinter({
		text: 'Be up-to-date',
		class: 'searchfield_hint'
	});
	
	// if ($('#q')[0].value == "Be up-to-date"){
	// 				$('#searchfield_div')[0].style.marginTop = "0px";
	// 			} else {
	// 				$('#searchfield_div')[0].style.marginTop = "5px";
	// 			}
	
});





function load_dialog_follow(product_name){	
	document.getElementById('product_to_follow').innerHTML = product_name;	
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

function textCounter(field, cntfield, maxlimit) {
	if (field.value.length > maxlimit) 
		field.value = field.value.substring(0, maxlimit);
	else
		cntfield.innerHTML = maxlimit - field.value.length;
}