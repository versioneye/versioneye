//Functions to handle Payment history on settings page
function render_loading_invoice(selector, data){
  var template = _.template(jQuery("#loading_invoice_template").html());
  jQuery(selector).html(template(data));
}

function render_empty_invoice(selector,data){
  var template = _.template(jQuery("#empty_invoice_template").html());
  jQuery(selector).html(template(data));
}

function render_invoice_table(selector, data){
  var template = _.template(jQuery("#invoice_table_template").html());
  jQuery(selector).html(template(data));
}

function render_invoice_row(selector, invoice){
  var template = _.template(jQuery("#invoice_row_template").html());
  jQuery(selector).append(template({invoice: invoice}));
}

function render_payment_history(selector, data){
  if (data.length == 0) {
    console.debug("Rendering empty invoices");
    render_empty_invoice(selector, {});
  } else {
    var invoice_rows = [];
    var row_selector = "#invoice_table > tbody";
    console.debug("Rendering table");
    render_invoice_table(selector, {});
    _.each(data, function(invoice){
      render_invoice_row(row_selector, invoice)
    } );
  }
}

function render_fail_invoice(selector, data){
  var template = _.template(jQuery("#fail_invoice_template").html());
  jQuery(selector).html(template({message: "Can not read payment history from Payment service"}));
}

jQuery(document).ready(function(){

  if(jQuery("#payment_history").length){
    console.debug("Going to render payment history...");
    _.templateSettings = {
      interpolate: /\{\{\=(.+?)\}\}/g,
      evaluate: /\{\{(.+?)\}\}/g
    };
    var content_selector = "#payment_history";
    render_loading_invoice(content_selector);

    var jqxhr = jQuery.getJSON("/settings/payments.json");

    //-- response handlers
    jqxhr.done(function(data, status, jqxhr){
      console.debug("Got invoices: " + status);
      render_payment_history(content_selector, data);
    });
    jqxhr.fail(function(data, status, jqxhr){
      console.debug("Failed invoices: " + status);
      render_fail_invoice(content_selector, data);
    });
  }
});
