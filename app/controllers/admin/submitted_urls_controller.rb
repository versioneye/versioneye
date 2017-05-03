class Admin::SubmittedUrlsController < ApplicationController

  before_action :admin_user

  def index
    @show_state = params[:by_state]
    @users = {}
    case @show_state
    when 'unchecked'
      @submitted_urls = SubmittedUrl.as_unchecked
    when 'checked'
      @submitted_urls = SubmittedUrl.as_checked
    when 'accepted'
      @submitted_urls = SubmittedUrl.as_accepted
    when 'declined'
      @submitted_urls = SubmittedUrl.as_declined
    when 'all'
      @submitted_urls = SubmittedUrl.all
    else
      @submitted_urls = SubmittedUrl.as_unchecked
    end
    @submitted_urls = @submitted_urls.desc(:created_at).paginate(page: params[:page], per_page: 10)
    @submitted_urls.each do |item|
      user_id = item.user_id
      @users[user_id] = User.find_by_id(user_id) unless user_id.nil?
    end
  end

  def approve
    submitted_url = SubmittedUrl.find_by_id params[:submitted_url_id]
    if submitted_url.nil?
      flash[:error] = "Can't approve: id of SubmittedUrl is missing."
    else
      new_resource = ProductResource.new(:url => params[:url],
                                         :name => params[:name],
                                         :resource_type => params[:resource_type],
                                         :submitted_url => submitted_url,
                                         :force_fullname => params[:force_fullname])
      if new_resource.save
        submitted_url.declined = false
        submitted_url.product_resource = new_resource
        submitted_url.save
        flash[:success] = 'Resource was accepted successfully'
        SubmittedUrlMailer.approved_url_email(submitted_url).deliver_now
      else
        flash[:error] = new_resource.errors.full_messages.to_sentence
      end
    end
    redirect_to :back
  end

  def decline
    submitted_url = SubmittedUrl.find_by_id params[:submitted_url_id]
    if submitted_url.nil?
      flash[:error] = "Can't decline: id of SubmittedUrl is missing."
    else
      submitted_url.declined = true
      submitted_url.declined_message = params[:declined_message]
      if submitted_url.save
        flash[:notice] = 'Url is now declined.'
        SubmittedUrlMailer.declined_url_email(submitted_url).deliver_now
      else
        flash[:error] - submitted_url.errors.full_messages.to_sentence
      end
    end
    redirect_to :back
  end

  def destroy
    item_id = (params[:id] or params[:submitted_url_id])
    submitted_url = SubmittedUrl.find_by_id item_id
    if submitted_url.nil?
      flash[:error] = "Can't delete: id of SubmittedUrl is missing."
    else
      submitted_url.delete
      flash[:notice] = 'Submitted Url is now deleted.'
    end
    redirect_to :back
  end

  private

    def admin_user
      redirect_to(root_path) unless signed_in_admin?
    end

end
