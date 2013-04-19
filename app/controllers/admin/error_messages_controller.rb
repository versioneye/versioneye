class Admin::ErrorMessagesController < ApplicationController

  def index 
    @errors = ErrorMessage.all().desc(:_id).paginate(:page => 1, :limit => 30)
    # @errors = ErrorMessage.all
  end  

end