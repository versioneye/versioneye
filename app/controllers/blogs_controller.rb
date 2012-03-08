class BlogsController < ApplicationController
  
  before_filter :authenticate, :except => [:index, :show]
  
  def index
    @blogs = Blog.find_approved_posts
  end
  
  def new
    @blog = Blog.new
  end
  
  def create
    @blog = Blog.new(params[:blog])
    @blog.user_id = current_user.id
    if @blog.save
      flash[:success] = "Your blog entry is submitted. As soon it gets approved it will be published."
      redirect_to '/blogs'
    else
      flash.now[:error] = "Something went wrong. Please try again later."
      render "new"
    end    
  end
  
  def edit
    @blog = Blog.find(params[:id])
  end
  
  def update
    @blog = Blog.find(params[:id])
    if @blog.update_attributes(params[:blog])
      flash[:success] = "Blog post was updated successfully."
      redirect_to userblogposts_path
    else
      flash.now[:error] = "Something went wrong. Please try again later."
      render edit_blog_path(@blog)
    end
  end
  
  def show
    
  end
  
  def show_user_posts
    @blogs = Blog.find_user_posts current_user.id
  end  
  
  def show_unapproved_posts
    @blogs = Blog.find_unapproved_posts
  end
  
  def blogpostapproval    
    post = Blog.find(params[:id])
    commit = params[:commit]
    p "commit: #{commit}"
    if commit == "Approve"
      post.approved = true
    else
      post.approved = false
    end
    post.reason = params[:reason]
    post.save
    redirect_to unapprovedblogposts_path
  end
  
end