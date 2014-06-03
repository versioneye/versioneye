class Settings::PaymentsController < ApplicationController

  before_filter :authenticate
  layout        :resolve_layout


  def index
    invoices = fetch_combined_invoices
    respond_to do |format|
      format.html
      format.json do
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
    @invoice = fetch_invoice params['invoice_id']

    # Ensure that the invoice belongs to the current logged in user!
    if @invoice &&
       !@invoice.customer.eql?( current_user.stripe_customer_id ) &&
       !@invoice.customer.eql?( current_user.stripe_legacy_customer_id )
      @invoice = nil
    end
  end


  private


    def fetch_invoice invoice_id
      invoice = StripeService.get_invoice( invoice_id )
      return invoice if invoice

      api_key = Settings.instance.stripe_legacy_secret_key
      StripeService.get_invoice( invoice_id, api_key )
    end


    def fetch_combined_invoices
      combined_invoices = []

      if current_user.stripe_customer_id
        customer_id       = current_user.stripe_customer_id
        customer_invoices = fetch_customer_invoices( customer_id )
        combined_invoices += fetch_invoice_array(customer_invoices)
      end

      if current_user.stripe_legacy_customer_id
        customer_id = current_user.stripe_legacy_customer_id
        legacy_invoices = fetch_legacy_invoices( customer_id )
        invoices = fetch_invoice_array(legacy_invoices)
        invoices.each do |inv|
          combined_invoices << inv
        end
      end

      combined_invoices
    end


    def fetch_customer_invoices customer_id
      customer          = StripeService.fetch_customer( customer_id )
      customer.invoices
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join('\n')
      []
    end


    def fetch_legacy_invoices customer_id
      api_key         = Settings.instance.stripe_legacy_secret_key
      customer        = StripeService.fetch_customer(customer_id, api_key)
      customer.invoices
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join('\n')
      []
    end


    def fetch_invoice_array customer_invoices
      invoices = []
      return invoices if customer_invoices.nil?

      customer_invoices.each do |invoice|
        next if invoice['lines'].to_s.empty?

        plan = fetch_plan invoice
        next if plan.nil?

        invoice[:date_s]    = Time.at( invoice.date ).to_date
        invoice[:plan_name] = plan['name']
        invoice[:amount_s]  = "#{sprintf('%.2f', (invoice.total / 100) )} #{invoice.currency.upcase}"
        invoice[:link_to]   = settings_receipt_path(invoice_id: invoice[:id])
        invoices << invoice
      end
      invoices
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join('\n')
      []
    end


    def fetch_plan invoice
      plan = nil
      if invoice['lines']['data']
        plan = invoice['lines']['data'].first['plan']
      elsif invoice['lines']['subscriptions']
        plan = invoice['lines']['subscriptions'].first['plan']
      end
      plan
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
