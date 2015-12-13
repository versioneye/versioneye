class Settings::PaymentsController < ApplicationController


  before_filter :authenticate


  def index
    @invoices = Receipt.by_user current_user.ids
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = 'An error occured. Please contact the VersionEye Team.'
    redirect_to settings_profile_path
  end


  def receipt
    @invoice = Receipt.by_invoice params['invoice_id']
    url = ''

    # Ensure that the invoice belongs to the current logged in user!
    if @invoice && @invoice.user.ids.eql?( current_user.ids ) &&
      url = S3.presigned_url(@invoice.filename)
    end

    redirect_to url
  end


end
