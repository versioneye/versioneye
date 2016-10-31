class OrganisationsController < ApplicationController


  before_filter :authenticate
  before_filter :auth_org_member, :only => [:projects, :show, :assign, :components, :pullrequests]
  before_filter :auth_org_owner,  :only => [:update, :delete, :destroy,
                                            :apikey, :update_apikey,
                                            :billing_address, :update_billing_address,
                                            :plan, :update_plan,
                                            :cc, :update_cc,
                                            :payment_history, :receipt]


  def new
    @organisation = Organisation.new
  end


  def create
    name = params[:organisation][:name]
    orga = OrganisationService.create_new current_user, name
    orga.company  = params[:organisation][:company]
    orga.location = params[:organisation][:location]
    orga.email    = params[:organisation][:email]
    orga.website  = params[:organisation][:website]
    orga.save
    redirect_to organisations_path
  rescue => e
    flash[:error] = e.message
    redirect_to :back
  end


  def destroy
    if OrganisationService.owner?(@organisation, current_user) || current_user.admin == true
      if OrganisationService.delete @organisation
        flash[:success] = "Organisation deleted successfully!"
      end
    else
      flash[:error] = "You are not allowed to delete organisation #{@organisation}!"
    end
    redirect_to organisations_path
  end


  def update
    @organisation.name     = params[:organisation][:name]
    @organisation.company  = params[:organisation][:company]
    @organisation.location = params[:organisation][:location]
    @organisation.email    = params[:organisation][:email]
    @organisation.website  = params[:organisation][:website]
    @organisation.mattp    = params[:organisation][:mattp]
    @organisation.matattp  = params[:organisation][:matattp]
    @organisation.matanmtt = params[:organisation][:matanmtt]
    @organisation.save
    flash[:success] = "Organisation saved successfully"
    redirect_to organisation_path(@organisation)
  rescue => e
    flash[:error] = e.message
    redirect_to :back
  end


  def show
    # see before_filter auth_org_member
  end


  def index
    @organisations = OrganisationService.index current_user
    redirect_to new_organisation_path if @organisations.empty?
  end


  def projects
    set_team_filter_param
    filter = {}
    filter[:organisation] = @organisation.ids
    filter[:team]         = params[:team]
    filter[:language]     = params[:language]
    filter[:version]      = params[:version]
    @projects = ProjectService.index current_user, filter, params[:sort]
    cookies.permanent.signed[:orga] = @organisation.ids
  end


  def assign
    @team = Team.where(:name => params[:team], :organisation_id => @organisation.ids).first
    pids = params[:project_ids].split(",")
    TeamService.assign @organisation.ids, @team.name, pids, current_user
    flash[:success] = "Projects have been assigned to the teams."
    redirect_to :back
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
  end


  def delete_projects
    pids = params[:project_delete_ids].to_s.split(",")
    pids.each do |pid|
      project = Project.find pid
      ProjectService.destroy project
    end
    flash[:success] = "Projects have been deleted."
    redirect_to :back
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_to :back
  end


  def components # Inventory
  end


  def apikey
  end


  def update_apikey
    api = @organisation.api
    api.generate_api_key!
    if @organisation.plan
      api.rate_limit = @organisation.plan.api_rate_limit
      api.comp_limit = @organisation.plan.cmp_rate_limit
    end

    unless api.save
      flash[:notice] << api.errors.full_messages.to_sentence
    end
    redirect_to :back
  end


  def billing_address
    @billing_address = @organisation.fetch_or_create_billing_address
    @billing_address.errors.messages.clear
  end

  def update_billing_address
    @billing_address = @organisation.fetch_or_create_billing_address
    if @billing_address.update_from_params params
      flash.now[:success] = "Your billing address was saved successfully."
    else
      flash.now[:error] = "An error occured. Please try again."
    end
    render "billing_address"
  end


  def cc
    plan = cookies.signed[:plan_selected]
    if plan
      @plan_name_id = plan
    end
    @billing_address = @organisation.fetch_or_create_billing_address
  end


  def update_cc
    billing_address = @organisation.fetch_or_create_billing_address
    if billing_address.update_from_params( params ) == false
      flash[:error] = 'Please complete the billing information.'
      redirect_to cc_organisation_path( @organisation )
      return
    end

    plan_name_id = params[:plan]
    stripe_token = params[:stripeToken]
    if stripe_token.to_s.empty? || plan_name_id.to_s.empty?
      flash[:error] = 'Stripe token is missing. Please contact the VersionEye Team.'
      redirect_to cc_organisation_path( @organisation )
      return
    end

    stripe_customer_id = @organisation.stripe_customer_id
    email = @organisation.fetch_or_create_billing_address.email
    customer = StripeService.create_or_update_customer stripe_customer_id, stripe_token, plan_name_id, email
    if customer.nil?
      flash[:error] = 'Stripe customer is missing. Please contact the VersionEye Team.'
      redirect_to cc_organisation_path( @organisation )
      return
    end

    @organisation.stripe_token = stripe_token
    @organisation.stripe_customer_id = customer.id
    @organisation.plan = Plan.by_name_id plan_name_id

    if @organisation.save
      flash[:success] = 'Many Thanks. We just updated your plan.'
      cookies.delete(:plan_selected)
      current_user.update_attribute( :verification, nil )
    else
      flash[:error] = "Something went wrong. Please contact the VersionEye team."
      Rails.logger.error "Can't save user - #{user.errors.messages}"
    end

    redirect_to plan_organisation_path( @organisation )
  end


  def plan
    if @organisation.plan.nil?
      @organisation.plan = Plan.free_plan
      @organisation.save
    end
    @plan = @organisation.plan
    cookies.permanent.signed[:plan_selected] = @plan.name_id
  end


   def update_plan
    @plan_name_id = params[:plan]
    stripe_token  = @organisation.stripe_token
    customer_id   = @organisation.stripe_customer_id
    customer      = nil
    Rails.logger.info "update_plan for #{@organisation.name} - #{@plan_name_id}"
    if customer_id && stripe_token
      customer = StripeService.fetch_customer customer_id
    end
    if customer
      Rails.logger.info "update_plan for #{@organisation.name} - #{@plan_name_id} - stripe customer exist already, just update plan."
      update_plan_for( @organisation, customer, @plan_name_id )
      redirect_to plan_organisation_path( @organisation )
    else
      Rails.logger.info "update_plan for #{@organisation.name} - #{@plan_name_id} - stripe customer does not exit, ask for CC data first."
      prepare_update_cc @plan_name_id
      redirect_to cc_organisation_path( @organisation )
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR in update_plan: #{e.message}"
    prepare_update_cc @plan_name_id
    redirect_to cc_organisation_path( @organisation )
  end


  def payment_history
    @invoices = Receipt.by_orga @organisation.ids
  end

  def receipt
    invoice = Receipt.by_invoice params['invoice_id']
    url = '/'

    # Ensure that the invoice belongs to the current logged in user!
    if invoice && invoice.organisation_id.to_s.eql?( @organisation.ids )
      presigned_url = S3.presigned_url(invoice.filename)
      url = presigned_url if !presigned_url.to_s.empty?
    end

    redirect_to url
  end


  def pullrequests
    @prs = Pullrequest.where(:organisation_ids => @organisation.ids).desc(:updated_at)
  end


  private


    def prepare_update_cc plan_name_id
      flash[:info] = 'Please update your Credit Card information.'
      cookies.permanent.signed[:plan_selected] = plan_name_id
      @billing_address = @organisation.fetch_or_create_billing_address
    end


    def update_plan_for organisation, customer, plan_name_id
      if plan_name_id.match(/\A04/).nil?
        flash[:error] = "The selected plan doesn't exist anymore."
        return nil
      end

      customer.update_subscription( :plan => plan_name_id )
      organisation.plan = Plan.by_name_id plan_name_id
      if organisation.save != true
        flash[:error] = 'Something went wrong. Please contact the VersionEye team.'
        return nil
      end

      # TODO refactor this for orga
      # SubscriptionMailer.update_subscription( user ).deliver_now
      flash[:success] = 'We updated your plan successfully.'

      cookies.delete(:plan_selected)

      api = organisation.api
      if api && organisation.plan
        api.rate_limit = organisation.plan.api_rate_limit
        api.comp_limit = organisation.plan.cmp_rate_limit
        api.save
      end
    end


    def set_team_filter_param
      if params[:team].to_s.empty?
        params[:team] = @organisation.teams_by(current_user).last.ids
      end
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
    end


    def auth_org_member
      @organisation = Organisation.where(:name => params[:name]).first
      return true if OrganisationService.member?(@organisation, current_user) || current_user.admin == true

      flash[:error] = "You are not a member of this organisation. You don't have the permission for this operation."
      redirect_to organisations_path
      return false
    end


    def auth_org_owner
      @organisation = Organisation.where(:name => params[:name]).first
      return true if OrganisationService.owner?(@organisation, current_user) || current_user.admin == true

      flash[:error] = "You are not in the Owners team. You don't have the permission for this operation."
      redirect_to organisations_path
      return false
    end

end
