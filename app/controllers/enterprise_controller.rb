class EnterpriseController < ApplicationController


  def show
    @ent_lead = EnterpriseLead.new
    render :layout => 'application_lp'
  end


  def create
    @ent_lead = EnterpriseLead.new
    @ent_lead.scm = params[:scm]
    @ent_lead.repository = params[:repository]
    @ent_lead.ci = params[:ci]
    @ent_lead.virtualization = params[:virtualization]
    @ent_lead.name = params[:name]
    @ent_lead.email = params[:email]
    @ent_lead.note = params[:note]
    if @ent_lead.save == true
      LeadMailer.new_lead( @ent_lead ).deliver_now
    else
      flash[:error] = "Something went wrong - #{@ent_lead.errors.full_messages.to_sentence}"
      redirect_to :back
    end
  end


  def activate
    api_key = params[:api_key]
    if !Set['1', 'on', 'true'].include?(params[:agreement])
      flash[:error] = "You have to accept the VersionEye Enterprise License Agreements"
      redirect_to :back and return
    end

    if EnterpriseService.activate!( api_key ) == false
      flash[:error] = "API Key could not be verified. Make sure that you have internet connection and the API Key is correct."
      redirect_to :back and return
    end

    flash[:success] = "Congratulation. Your VersionEye Enterprise instance is activated. Login with admin/admin."
    redirect_to signin_path
  end


end
