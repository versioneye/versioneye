class VersioncommentrepliesController < ApplicationController

  before_filter :authenticate

  def create
    user = current_user
    @versioncomment               = Versioncomment.find_by_id(params[:comment_id])
    @versioncommentreply          = Versioncommentreply.new
    @versioncommentreply.comment  = params[:versioncommentreply][:comment]
    @versioncommentreply.user_id  = user.id
    @versioncommentreply.fullname = user.fullname
    @versioncommentreply.username = user.username

    @versioncomment.versioncommentreplys << @versioncommentreply

    prod_key = @versioncomment.product_key
    version  = @versioncomment.version
    @product = Product.fetch_product( @versioncomment.language, prod_key )
    @versioncomment.prod_name = @product.name
    @versioncomment.language = @product.language
    attach_version(@product, version)
    saved = false
    if @versioncomment.save
      saved = true
      send_comment_reply_mails(user, @versioncomment)
    end
    respond_to do |format|
      format.html {
        if saved
          flash[:success] = 'Comment saved!'
        else
          flash[:error] = 'Something went wrong'
        end
        redirect_to product_version_path(@product)
      }
      format.js { }
    end
  end

  private

    def send_comment_reply_mails(user, comment)
      comment_user = comment.user
      unless comment_user.username.eql?(user.username)
        VersioncommentreplyMailer.versioncomment_reply_email(comment_user, user, comment).deliver
      end
    end

end
