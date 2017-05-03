class LicensesController < ApplicationController

  before_action :authenticate

  def new
    @license = License.new({:language => params[:language], :prod_key => params[:prod_key], :version => params[:version] })
  end

  def create
    p params
    ls = LicenseSuggestion.new({:language => params[:license][:language],
                                :prod_key => params[:license][:prod_key],
                                :version => params[:license][:version],
                                :name => params[:license][:name],
                                :url => params[:license][:url],
                                :comments => params[:license][:comments],
                                :user_id => current_user.ids})
    if ls.save
      LicenseMailer.new_license_suggestion(ls).deliver_now
    else
      flash[:error] = "#{ls.errors.full_messages.to_sentence}."
      redirect_to :back
      return
    end
  end

end
