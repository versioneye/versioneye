class BlogcommentsController < ApplicationController
  
  before_filter :authenticate
  
  def create
    blogcomment = Blogcomment.new(params[:blogcomment])
    blogcomment.blog_id = params[:blog_id]
    blogcomment.user_id = current_user.id
    comment = blogcomment.comment
    if (comment.include?("<img") || comment.include?("<script") || comment.include?("<a"))
      flash[:error] = "Please don't use HTML tags in your comment!"      
    elsif blogcomment.save
      flash[:success] = "Your comment is saved."
    else
      flash[:error] = "An error occured. Please try again later."
    end
    @blog = Blog.find(params[:blog_id])
    redirect_to "/blogs/show/#{@blog.title}/#{@blog.id}"
  end

end