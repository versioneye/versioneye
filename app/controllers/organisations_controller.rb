class OrganisationsController < ApplicationController


  before_action :authenticate
  before_action :load_orga_by_name
  before_action :auth_org_member, :only => [:projects, :show, :assign, :components, :pullrequests]
  before_action :auth_org_owner,  :only => [:update, :delete, :destroy,
                                            :apikey, :update_apikey,
                                            :billing_address, :update_billing_address,
                                            :plan, :update_plan,
                                            :cc, :update_cc,
                                            :payment_history, :receipt]
  before_action :export_permission?, :only => [:inventory_csv]


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
    redirect_back
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
    @organisation.skip_license_check_on_pr = params[:organisation][:skip_license_check_on_pr]
    @organisation.save
    flash[:success] = "Organisation saved successfully"
    redirect_to organisation_path(@organisation)
  rescue => e
    flash[:error] = e.message
    redirect_back
  end


  def show
    # see before_action auth_org_member
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
    single_assignment = false
    single_assignment = true if params[:single_assignment].to_s.eql?("1")
    TeamService.assign @organisation.ids, @team.name, pids, current_user, single_assignment
    flash[:success] = "Projects have been assigned to the teams."
    redirect_back
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_back
  end


  def delete_projects
    pids = params[:project_delete_ids].to_s.split(",")
    pids.each do |pid|
      project = Project.find pid
      ProjectService.destroy project
    end
    flash[:success] = "Projects have been deleted."
    redirect_back
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_back
  end


  def components # Inventory
  end

  def inventory_diff
  end

  def inventory_diff_show
    id = params[:id]
    @diff = InventoryDiff.where(:organisation_id => @organisation.ids, :id => id).first
  end

  def inventory_diff_create
    team      = params[:team1]
    team      = 'ALL' if team.to_s.empty?

    language  = params[:language1]
    language  = 'ALL' if language.to_s.empty?

    pversion  = params[:version1]
    pversion  = 'ALL' if pversion.to_s.empty?

    post_filter  = params[:duplicates1]
    post_filter  = 'ALL' if post_filter.to_s.empty?

    filter1 = {:team => team, :language => language, :version => pversion, :after_filter => post_filter}
    p "filter1: #{filter1}"

    team      = params[:team2]
    team      = 'ALL' if team.to_s.empty?

    language  = params[:language2]
    language  = 'ALL' if language.to_s.empty?

    pversion  = params[:version2]
    pversion  = 'ALL' if pversion.to_s.empty?

    post_filter  = params[:duplicates2]
    post_filter  = 'ALL' if post_filter.to_s.empty?

    filter2 = {:team => team, :language => language, :version => pversion, :after_filter => post_filter}
    p "filter2: #{filter2}"

    @diff_id = OrganisationService.inventory_diff_async @organisation.name, filter1, filter2
  end

  def inventory_diff_status
    id = params[:id]
    @diff = InventoryDiff.where(:organisation_id => @organisation.ids, :id => id).first
    respond_to do |format|
      format.json
      format.text
    end
  end


  def inventory_csv
    pteam = params['team']
    pteam = 'ALL' if pteam.to_s.empty?
    planguage = params['language']
    planguage = 'ALL' if planguage.to_s.empty?
    pversion = params['version']
    pversion = 'ALL' if pversion.to_s.empty?
    pduplicates = params['duplicates']
    pduplicates = 'ALL' if pduplicates.to_s.empty?
    csv = @organisation.component_list_csv(pteam, planguage, pversion, pduplicates)
    send_data csv, type: 'text/csv', filename: "#{@organisation.name}_inventory.csv"
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    flash[:error] = "ERROR: #{e.message}"
    redirect_back
  end


  def apikey
  end


  def update_apikey
    read_only = false
    read_only = true if params[:submit_ro]
    api = @organisation.api(read_only)
    api.generate_api_key!
    if @organisation.plan
      api.rate_limit = @organisation.plan.api_rate_limit
      api.comp_limit = @organisation.plan.cmp_rate_limit
    end

    unless api.save
      flash[:notice] << api.errors.full_messages.to_sentence
    end
    redirect_back
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
    if plan_name_id.to_s.empty? && @organisation.plan
      plan_name_id = @organisation.plan.name_id
    end

    stripe_token = params[:stripeToken]
    if stripe_token.to_s.empty?
      stripe_token = @organisation.stripe_token
    end

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

  def plan_enterprise
    if @organisation.plan.nil?
      @organisation.plan = Plan.free_plan
      @organisation.save
    end
    @plan = @organisation.plan
    cookies.permanent.signed[:plan_selected] = @plan.name_id
  end


  def update_plan
    @plan_name_id = params[:plan]
    @plan_name_id = '04_free' # Only free plan is allowed now because of sunset process! 
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
    @prs = []
    count = Pullrequest.where(:organisation_ids => @organisation.ids).count
    if count.to_i > 100
      @prs = Pullrequest.where(:organisation_ids => @organisation.ids).skip( count - 100 ).to_a.reverse
    else
      @prs = Pullrequest.where(:organisation_ids => @organisation.ids).desc(:updated_at)
    end
  end


  private


    def export_permission?
      return true if Rails.env.enterprise? == true

      if defined?(@organisation).nil? || @organisation.nil?
        flash[:warning] = "This feature is only available for projects inside of an organisation."
        return false
      end

      if @organisation.pdf_exports_allowed? == false
        flash[:warning] = "For the PDF/CSV export you need a higher plan. Please upgrade your subscription."
        redirect_to plan_organisation_path( @organisation )
        return false
      end
      return true
    end


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
        team = @organisation.teams_by(current_user).last
        params[:team] = team.ids if team
      end
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
    end

end
