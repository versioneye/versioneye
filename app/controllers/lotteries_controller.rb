class LotteriesController < ApplicationController
  layout "lottery"
  before_filter :authenticate, :only => [:show_lottery, :new_lottery, :show_thankyou]

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

  def show_lottery
    @products = Product.all.desc(:followers).limit(12)

    render template: "/lotteries/show_lottery"
  end

  def show_thankyou
    @tickets = Lottery.by_user(current_user)
    @deadline = Date.new(2013, 10, 31)
    @today = Date.today

    render template: "/lotteries/show_thankyou"
  end

  def new_lottery
    product_keys = params[:products] || []
    failed = []
    product_keys.each do |prod_key|
      prod_key = Product.decode_prod_key(prod_key)
      prod = Product.find_by_key(prod_key)
      result = ProductService.follow(prod[:language], prod_key, current_user)

      failed << prod_key unless result #remember failed follow
    end

    #go back when user failed to follow some  products
    unless failed.empty?
      flash[:error] = "Unlucky selection; Cant follow #{failed.join(',')}. Please try again."
      redirect_to :back  and return true
    end

    lottery = Lottery.new user_id: current_user.id,
                          selection: product_keys

    lottery.save
    redirect_to "/lottery/thankyou"
  end
end
