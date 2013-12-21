class Admin::TestimonialsController < ApplicationController

  before_filter :admin_user

  def index
  end

  def show
    page = params[:page] || 1
    @testimonials = Testimonial.asc(:moderated).paginate(page: page, per_page: 30)
  end

  def approve
    testimonial = get_testimonial(params)
    testimonial.update_attributes moderated: true,
                                  approved: true
    if testimonial.save
      flash[:notice] = 'Success! Testimonial is now accepted.'
    else
      flash[:error] = "Error! Can't save updates! #{testimonial.errors.full_messages.to_sentence}"
    end
    redirect_to :back
  end

  def decline
    testimonial = get_testimonial(params)
    testimonial.update_attributes moderated: true,
                                  approved: false
    if testimonial.save
      flash[:notice] = 'Success! Testimonial is now banned.'
    else
      flash[:error] = "Error! Can't save updates! #{testimonial.errors.full_messages.to_sentence}"
    end
    redirect_to :back
  end

  private

  def get_testimonial(params)
    unless params[:testimonial] and params[:testimonial][:id]
      flash[:error] = "Can't approve given testimonial, because request didnt have testimonial id"
      redirect_to :back and return
    end

    testimonial = Testimonial.find_by_id(params[:testimonial][:id])
    if testimonial.nil?
      flash[:error] = 'Can not approve given testimonial, because it doesnt exist anymore.'
      redirect_to :back and return
    end

    testimonial
  end

  private

    def admin_user
      redirect_to(root_path) unless signed_in_admin?
    end


end
