class User::TestimonialsController < ApplicationController
  before_filter :authenticate, only: [:create, :update]

  def index
    @testimonial = Testimonial.new
  end

  def show
    @user = current_user
    @testimonial = Testimonial.new
    @testimonial = Testimonial.find_by_id(params[:id]) if params.has_key?(:id)
  end

  def create
    new_testimonial = Testimonial.new(params[:testimonial])
    new_testimonial.user_id = current_user.id
    if new_testimonial.save
      flash[:success] = "Your testimonial is added successfully!"
    else
      flash[:error] = "Our database refused to save your testimonial."
    end
    redirect_to action: 'show', id: new_testimonial.id
  end

  def update
    testimonial = Testimonial.find_by_id(params[:testimonial][:_id])
    if testimonial.nil?
      flash[:error] = "Cant update - someone stole id of your testimony."
      redirect_to :back and return
    end
    testimonial.update_attributes!(params[:testimonial])
    if testimonial.save
      flash[:success] = "Your's testimonial is now updated."
    else
      flash[:error] = "Sorry! Cant save your updates."
    end
    redirect_to action: 'show', id: testimonial.id
  end

end
