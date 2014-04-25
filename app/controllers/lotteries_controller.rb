class LotteriesController < ApplicationController

  layout 'lottery'

  before_filter :authenticate, :only => [:libraries, :follow, :thankyou]

  def index
    render text: 'Uhh, sorry but you shouldnt see this.'
  end

  def show
    @user = current_user
  end

  def show_verification
    verification = params[:verification]
    if User.activate!(verification)
      flash[:success] = 'Congratulation. Your Account is activated. Please Sign in.'
      redirect_to '/lottery/signin' and return
    end

    flash[:error] = 'Sorry! Verification failed.'
    redirect_to '/lottery' #if failed, move back to lottery landing page
  end

  def show_signin
    render template: 'lotteries/_signin_form'
  end

  def libraries
    unless valid_ticket?
      redirect_to '/lottery/thankyou' and return
    end

    @products = Product.all.desc(:followers).limit(12)
    render template: '/lotteries/libraries'
  end

  def thankyou
    @tickets = Lottery.by_user(current_user)
    @deadline = Date.new(2013, 10, 31)
    @today = Date.today
    render template: '/lotteries/thankyou'
  end

  def follow
    unless valid_ticket?
      redirect_to '/lottery/thankyou' and return
    end

    product_tokens = params[:products] || []
    product_keys = []

    product_tokens.each do |prod_token|
      language, prod_key = prod_token.split(',')
      language = Product.decode_language(language)
      prod_key = Product.decode_prod_key(prod_key)
      product_keys << {language: language, prod_key: prod_key}
      ProductService.follow(language, prod_key, current_user)
    end

    lottery = Lottery.new user_id: current_user.id, selection: product_keys
    lottery.save

    UserMailer.new_ticket(current_user, lottery).deliver
    redirect_to '/lottery/thankyou'
  rescue => e
    Rails.logger.error e
  end

  private

    def valid_ticket?
      if Lottery.by_user(current_user).count > 0
        flash[:error] = 'You already have a ticket.'
        return false
      end
      true
    end

end
