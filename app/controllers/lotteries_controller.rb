class LotteriesController < ApplicationController

  force_ssl if Rails.env.production?

  layout "lottery"

  before_filter :authenticate, :only => [:libraries, :follow, :thankyou]

  def index
    render text: "Uhh, sry but you shouldnt see this."
  end

  def show
    @user = current_user
  end

  def show_verification
    verification = params[:verification]
    if User.activate!(verification)
      flash[:success] = "Congratulation. Your Account is activated. Please Sign In."
      redirect_to "/lottery/signin" and return
    end

    flash[:error] = "Sorry! Verification failed."
    redirect_to "/lottery" #if failed, move back to lottery landing page
  end

  def show_signin
    render template: "lotteries/_signin_form"
  end

  def libraries
    if Lottery.by_user(current_user).count > 0
      flash[:success] = "You already have a ticket."
      redirect_to thankyou_lottery_path and return
    end

    @products = Product.all.desc(:followers).limit(12)
    render template: "/lotteries/libraries"
  end

  def thankyou
    @tickets = Lottery.by_user(current_user)
    @deadline = Date.new(2013, 10, 31)
    @today = Date.today
    render template: "/lotteries/thankyou"
  end

  def follow
    product_keys = params[:products] || []
    # TODO parse langauge and prod_key
    product_keys.each do |prod_key|
      prod_key = Product.decode_prod_key(prod_key)
      prod     = Product.find_by_key(prod_key) # TODO Product.fetch_product(language, prod_key)
      result   = ProductService.follow(prod[:language], prod_key, current_user)
    end

    lottery = Lottery.new user_id: current_user.id, selection: product_keys
    lottery.save

    UserMailer.new_ticket(current_user, lottery).deliver
    redirect_to "/lottery/thankyou"
  rescue => e
    Rails.logger.error e
  end

end
