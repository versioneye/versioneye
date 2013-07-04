class LanguageController < ApplicationController

  def show
    sample_size = 24
    max_population_size = 10 * sample_size
    start_collecting_from = Random.rand(User.all.count - max_population_size)
    @lang = Product.decode_language(params[:lang]) 
    @top_products = Product.by_language(@lang).desc(:followers).limit(10)
    @latest_products = Product.by_language(@lang).desc(:updated_at).limit(10)
    @followers = []

    #build sample population of followers 
    population = [] 
    User.skip(start_collecting_from).each do |user|
      population << user if user.products.where(language: @lang).exists?
      break if population.count >= 256
    end

    #pick random followers from population
    @followers = population.sample(24)
    @vulnerabilities = [] 
    ProductSecurityNotification.by_language(@lang).each do |notif|
      @vulnerabilities << SecurityNotification.find(notif.security_notification_id)
    end

    @feeds = LanguageFeed.by_language(@lang).map(&:url)
    render template: "language/show"

  end
end
