class Admin::ErrorMessagesController < ApplicationController

  def index 
    @errors = ErrorMessage.fetch_page(params[:page])
  end  

end