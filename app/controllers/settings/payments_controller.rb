class Settings::PaymentsController < ApplicationController

  before_filter :authenticate
  layout        :resolve_layout


  def index
    customer_id       = current_user.stripe_customer_id
    customer          = StripeService.fetch_customer(customer_id) if customer_id
    customer_invoices = customer.invoices unless customer.nil?

    respond_to do |format|
      format.html
      format.json do
        invoices = fetch_invoices customer_invoices
        render json: invoices
      end
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = 'An error occured. Please contact the VersionEye Team.'
    redirect_to settings_profile_path
  end


  def receipt
    @invoice = StripeService.get_invoice( params['invoice_id'] )
    # Ensure that the invoice belongs to the current logged in user!
    if @invoice && !@invoice.customer.eql?( current_user.stripe_customer_id )
      @invoice = nil
    end
    @billing_address = current_user.billing_address
  end


  private


    def fetch_invoices customer_invoices
      invoices = []
      return invoices if customer_invoices.nil?

      customer_invoices.each do |invoice|
        next if invoice['lines'].to_s.empty?
        next if invoice['lines']['data'].to_s.empty?

        plan = invoice['lines']['data'].first['plan']
        next if plan.nil?

        invoice[:date_s]    = Time.at( invoice.date ).to_date
        invoice[:plan_name] = plan['name']
        invoice[:amount_s]  = "#{sprintf('%.2f', (invoice.total / 100) )} #{invoice.currency.upcase}"
        invoice[:link_to]   = settings_receipt_path(invoice_id: invoice[:id])
        invoices << invoice
      end
      invoices
    end


    def resolve_layout
      case action_name
      when 'receipt'
        'plain'
      else
        'application'
      end
    end

end
