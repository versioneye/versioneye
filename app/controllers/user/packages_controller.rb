class User::PackagesController < ApplicationController

  before_action :authenticate

  def i_follow
    @products = current_user.products.paginate(:page => params[:page])
    if @products.nil? || @products.empty?
      @popular_packages = Product.all().desc(:followers).limit(10)
    end
  end

end
