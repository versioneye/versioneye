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
      redirect_to myposts_blogs_path
    else
      flash.now[:error] = "Something went wrong. Please try again later."
      render edit_blog_path(@blog)
    end
  end
  
  def show
    @blog = Blog.find(params[:id])
    @comments = @blog.comments
    @blogcomment = Blogcomment.new
  end
  
  def myposts
    @blogs = Blog.find_user_posts current_user.id
  end
  
  def unapproved
    @blogs = Blog.find_unapproved_posts
  end
  
  def approval    
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
    redirect_to unapproved_blogs_path
  end
  
end