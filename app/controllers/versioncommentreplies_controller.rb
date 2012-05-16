class VersioncommentrepliesController < ApplicationController
  
  before_filter :authenticate

  def create
    user = current_user
    @versioncomment = Versioncomment.find_by_id(params[:comment_id])
    @versioncommentreply = Versioncommentreply.new(params[:versioncommentreply])
    @versioncommentreply.user_id = user.id
    @versioncommentreply.fullname = user.fullname
    @versioncommentreply.username = user.username

    @versioncomment.versioncommentreplys << @versioncommentreply

    prod_key = @versioncomment.product_key
    ver = @versioncomment.version
    @product = Product.find_by_key(prod_key)
    @versioncomment.prod_name = @product.name
    @versioncomment.language = @product.language
    attach_version(@product, ver)
    saved = false;
    if @versioncomment.save      
      saved = true
      send_comment_reply_mails(user, @versioncomment)
    end        
    respond_to do |format|
      format.html { 
        if saved 
          flash[:success] = "Comment saved!"
        else 
          flash[:error] = "Something went wrong"
        end
        redirect_to product_version_path(@product)
      }
      format.js { }
    end
  end
  
  private 
      
    def send_comment_reply_mails(user, comment)
      comment_user = comment.user
      if !comment_user.username.eql?(user.username)
        product = comment.get_product
        VersioncommentreplyMailer.versioncomment_reply_email(comment_user, user, comment, product).deliver
      end
    end
  
end