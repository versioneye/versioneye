class EnterpriseController < ApplicationController

  def show 
    render :layout => 'application_lp'
  end

  def activate
    api_key = params[:api_key]
    if !Set['1', 'on', 'true'].include?(params[:agreement])
      flash[:error] = "You have to accept the VersionEye Enterprise License Agreements"
      redirect_to :back and return
    end

    if !EnterpriseService.activate!( api_key )
      flash[:error] = "API Key could not be verified. Make sure that you have internet connection and the API Key is correct."
      redirect_to :back and return
    end

    flash[:success] = "Congratulation. Your VersionEye Enterprise instance is activated. Login with admin/admin."
    redirect_to signin_path
  end

end
