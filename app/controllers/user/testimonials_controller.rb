class User::TestimonialsController < ApplicationController

  before_filter :authenticate, only: [:create, :update]

  def index
    @testimonial = Testimonial.new
  end

  def show
    if signed_in?
      @user = current_user
      if @user.testimonial
        redirect_to edit_user_testimonials_path and return
      end
    end

    redirect_to new_user_testimonials_path
  end

  def new
    @user = current_user
    @testimonial = Testimonial.new
  end

  def edit
    @user = current_user
    @testimonial = current_user.testimonial
  end

  def create
    new_testimonial = Testimonial.new(params[:testimonial])
    new_testimonial.user_id = current_user.id

    if new_testimonial.save(validate: false)
      flash.now[:success] = 'Many Thanks for your testimonial. Your feedback is highly appreciated.'
      @testimonial = new_testimonial.content
      render 'tweet'
    else
      flash.now[:error] = 'Ups. Something went wrong. Please reach out to the VersionEye Team and help them to improve the product.'
      redirect_to action: 'show'
    end
  end

  def update
    testimonial = Testimonial.find_by_id(params[:testimonial][:_id])
    if testimonial.nil?
      flash.now[:error] = 'Ups. Something went wrong. Please reach out to the VersionEye Team and help them to improve the product.'
      redirect_to :back and return
    end
    testimonial.update_attributes!(params[:testimonial])
    if testimonial.save
      flash.now[:success] = 'Many Thanks for your testimonial. Your feedback is highly appreciated.'
      @testimonial = testimonial.content
      render 'tweet'
    else
      flash.now[:error] = 'Ups. Something went wrong. Please reach out to the VersionEye Team and help them to improve the product.'
      redirect_to action: 'show'
    end
  end

end
