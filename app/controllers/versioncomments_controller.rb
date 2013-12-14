class VersioncommentsController < ApplicationController

  before_filter :authenticate, :except => [:show]

  def create
    user                      = current_user
    @versioncomment           = Versioncomment.new(params[:versioncomment])
    @versioncomment.user_id   = user.id
    version                   = @versioncomment.version
    @product                  = @versioncomment.product
    @versioncomment.prod_name = @product.name
    @versioncomment.language  = @product.language
    attach_version(@product, version)
    if @versioncomment.save
      flash[:success] = 'Comment saved!'
      send_comment_mails(@product, user, @versioncomment)
    else
      flash[:error] = 'Something went wrong'
    end
    redirect_to product_version_path(@product)
  end

  def show
    id = params[:id]
    @versioncommentreply = Versioncommentreply.new()
    @comment = Versioncomment.find_by_id(id)
    if @comment
      @product = @comment.product
      attach_version(@product, @comment.version)
    else
      flash.now[:error] = "Sorry. We are not able to find the requested comment. Maybe it was deleted."
    end
  end

  private

    def send_comment_mails(product, user, comment)
      return nil if product.users.nil? || product.users.empty?
      send_to_users = Array.new
      product.users.each do |follower|
        if !follower.id.to_s.eql?(user.id.to_s) && follower.deleted == false
          VersioncommentMailer.versioncomment_email(product, follower, user, comment).deliver
          send_to_users << follower
        end
      end
      send_to_users
    end

end
