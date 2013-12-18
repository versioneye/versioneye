class EmailhelperController < ApplicationController

  def show
    @fullname = "Richard Metzler"
    render :file => "../mailers/suggest_packages_email.html.erb", :layout => nil
  end

end
