class VersioncommentsController < ApplicationController

  before_filter :authenticate, :except => [:show]
  
  def create
    user = current_user
    @versioncomment = Versioncomment.new(params[:versioncomment])
    @versioncomment.user_id = user.id
    prod_key = @versioncomment.product_key
    ver = @versioncomment.version
    @product = Product.find_by_key(prod_key)
    @versioncomment.prod_name = @product.name
    @versioncomment.language = @product.language
    attach_version(@product, ver)
    if @versioncomment.save      
      flash[:success] = "Comment saved!"
      send_comment_mails(@product, user, @versioncomment)
    else 
      flash[:error] = "Something went wrong"
    end        
    redirect_to product_version_path(@product)
  end
  
  def show 
    id = params[:id]
    @versioncommentreply = Versioncommentreply.new()
    @comment = Versioncomment.find_by_id(id)
    if !@comment.nil?
      @product = Product.find_by_key(@comment.product_key)
      attach_version(@product, @comment.version)
    else
      flash.now[:error] = "Sorry. We are not able to find the requested comment. Maybe it was deleted."
    end
  end
  
  private 
      
    def send_comment_mails(product, user, comment)
      # TODO refactor this with product.users relation 
      followers = Follower.find_by_product(product.id.to_s)
      
      if followers.nil? || followers.empty?
        return nil
      end
      
      followers.each do |follower|
        if !follower.user_id.eql?(user.id.to_s)
          follower_user = follower.user
          next if follower_user.deleted
          VersioncommentMailer.versioncomment_email(product, follower.user, user, comment).deliver
        end
      end
    end
  
end