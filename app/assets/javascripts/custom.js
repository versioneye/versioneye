
$(document).ready(function() {
	
});

function follow_link(product_name, product_key){
	$('#dialog_follow').dialog(
		{
		resizable: false, 
		modal: true, 
		draggable: false, 
		minWidth: 600, 
		create: function(event, ui) { 
			document.getElementById('product_to_follow').innerHTML = product_name;
			document.getElementById('product_hidden').value = product_key;
			}
		});
}

function validateEmail(elementValue){  
	var emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;  
	return emailPattern.test(elementValue);  
}