class VersioncommentsController < ApplicationController
  
  def create
    user = current_user
    @versioncomment = Versioncomment.new(params[:versioncomment])
    @versioncomment.user = user
    @versioncomment.rate = 0 if @versioncomment.rate.nil?
    prod_key = @versioncomment.product_key
    ver = @versioncomment.version
    @product = Product.find_by_key(prod_key)
    attach_version(@product, ver, nil)
    
    if @versioncomment.save      
      flash[:success] = "Comment saved!"
      send_comment_mails(@product, user, @versioncomment)
    else 
      flash[:error] = "Something went wrong"
    end        
    
    update_product_rate(@product, ver)     
    redirect_to product_version_path(@product)
  end
  
  def show 
    id = params[:id]
    @comment = Versioncomment.find_by_id(id)
    if !@comment.nil?
      @product = Product.find_by_key(@comment.product_key)
      attach_version(@product, @comment.version, nil)
    end
  end
  
  private 
  
    def update_product_rate(product, ver)
      version = product.get_version(ver)
      version.update_rate      
      version.save      
      product.update_rate
      product.save
    end
    
    def send_comment_mails(product, user, comment)
      followers = Follower.find_by_product(product.id.to_s)
      
      if followers.nil? || followers.empty?
        return nil
      end
      
      followers.each do |follower|
        follower_user = follower.user
        if follower_user.id != user.id
          # VersioncommentMailer.delay.versioncomment_email(product, follower_user, user, comment)
          VersioncommentMailer.versioncomment_email(product, follower_user, user, comment).deliver
        end
      end
    end
  
end