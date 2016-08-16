class PullrequestsController < ApplicationController


  before_filter :load_orga


  def index
    @prs = []
    if defined?(@organisation) && !@organisation.nil?
      @prs = Pullrequest.where(:organisation_ids => @organisation.ids).desc(:updated_at)
    elsif current_user && current_user.admin == true
      @prs = Pullrequest.all.desc(:updated_at)
    end
  end


  def show
    @pr = Pullrequest.find params[:id]
  end


  private


    def load_orga
      orga_id = cookies.signed[:orga]
      return nil if orga_id.to_s.empty?

      @organisation = Organisation.find orga_id
    end


end
