class LanguageController < ApplicationController

  def index
    @languages = Language.all.desc(:updated_at)
  end

  def show
    @lang            = Product.decode_language(params[:lang])
    @top_products    = Product.by_language(@lang).desc(:followers).limit(10)
    @most_referenced_products = Product.by_language(@lang).desc(:used_by_count).limit(10)
    @latest_products = Newest.by_language(@lang).desc(:created_at).limit(10)
    @latest_stats    = LanguageDailyStats.latest_stats(@lang)

    @languages = Product::A_LANGS_LANGUAGE_PAGE
    @language  = Language.where(name: @lang).first
    @followers = []

    @followers = fetch_followers @lang

    @authors = Author.where(:languages => @lang).desc(:products_count).limit(10)

    # lang_pattern = Regexp.new(@lang.downcase, true)
    # @vulnerabilities = SecurityNotification.all.in(languages: [lang_pattern]).desc(:modified).limit(30)

    # @feeds = LanguageFeed.by_language(@lang).map(&:url)
    # render template: "language/show"
  end

  def show_block
    lang = Product.decode_language(params[:lang])
    language = Language.where(name: lang).first
    render partial: 'language/helpers/language_block', locals: {language: language}
  end

  def new
    @language = Language.new
  end

  def edit
    lang_name = Product.decode_language(params[:lang])
    @language = Language.where(name: lang_name).first
  end

  def create
    new_lang = Language.new(params[:language])
    new_lang[:name] = Product.decode_language(params[:lang])
    new_lang[:param_name] = Product.encode_language(new_lang[:name])

    if new_lang.save
      flash[:success] = 'Language is added successfully.'
      redirect_to language_path
    else
      flash[:error] = "Can not save language: #{new_lang.errors.full_messages.to_sentence}"
      redirect_back
    end
  end

  def update
    updated_language = params[:language]
    old_language = Language.where(name: updated_language[:name]).first
    old_language.update_attributes!(updated_language)
    if old_language.save
      flash[:success] = 'Language is now opdated.'
      redirect_to "/language/#{old_language[:param_name]}"
    else
      flash[:error] = 'Can not save updates.'
      redirect_back
    end
  end

  def most_referenced
    page = params[:page]
    @lang = Product.decode_language(params[:lang])
    @products = ProductService.most_referenced @lang, page
  end

  def random30
    rows = []
    30.times do |n|
      rows << {"date" => n.days.ago.strftime("%d-%m-%Y"), "value" => Random.rand(1000)}
    end

    render json: rows
  end

  private

    def fetch_followers lang
      key = "#{lang}_followers"
      followers = Rails.cache.read key
      return followers if !followers.to_s.empty?

      population = []
      users = User.where(:languages => /\"#{lang}\"/).limit(50)
      users.each do |user|
        population << user
      end
      followers = population.sample(30) # pick random followers from population
      Rails.cache.write( key, followers, timeToLive: 1.day )
      followers
    end

end
