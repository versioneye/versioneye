class PullrequestsController < ApplicationController


  def index
    @prs = Pullrequest.all.desc(:updated_at) # TODO add contstraint for orga
    @organisation = Organisation.where(:name => params[:name]).first
  end


  def show
    id = params[:id]
    @organisation = Organisation.where(:name => params[:name]).first
    @pr = Pullrequest.find id
  end


end
