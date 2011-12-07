
$(document).ready(function() {
	
});

function follow_link(product_name){
	$('#dialog_follow').dialog(
		{
		resizable: false, 
		modal: true, 
		draggable: false, 
		minWidth: 600, 
		create: function(event, ui) { 
			document.getElementById('product_to_follow').innerHTML = product_name;
			}
		});
}