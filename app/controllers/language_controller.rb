class LanguageController < ApplicationController

  def show
    sample_size           = 24
    max_population_size   = 10 * sample_size
    start_collecting_from = Random.rand(User.all.count - max_population_size)
    @lang            = Product.decode_language(params[:lang])
    @top_products    = Product.by_language(@lang).desc(:followers).limit(10)
    @latest_products = Newest.by_language(@lang).desc(:created_at).limit(10)
    @followers = []

    #build sample population of followers
    population = []
    User.skip(start_collecting_from).each do |user|
      population << user if user.products.where(language: @lang).exists?
      break if population.count >= 100
    end

    #pick random followers from population
    @followers = population.sample(12)

    # lang_pattern = Regexp.new(@lang.downcase, true)
    # @vulnerabilities = SecurityNotification.all.in(languages: [lang_pattern]).desc(:modified).limit(30)

    # @feeds = LanguageFeed.by_language(@lang).map(&:url)
    # render template: "language/show"

  end
end
