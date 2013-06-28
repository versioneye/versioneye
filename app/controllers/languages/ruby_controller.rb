class Languages::RubyController < ApplicationController
  
  def index
    @lang = Product::A_LANGUAGE_RUBY
    @top_products = Product.by_language(@lang).desc(:followers).limit(10)
    @latest_products = Product.by_language(@lang).desc(:updated_at).limit(10)
    @followers = []

    #build sample population of followers 
    population = []
    Product.by_language(@lang).limit(1024).each do |product|
      population.concat(product.users)
      break if population.count >= 256
    end

    #pick random followers from population
    @followers = population.sample(24)
    @vulnerabilities = [] 
    ProductSecurityNotification.by_language(@lang).each do |notif|
      @vulnerabilities << SecurityNotification.find(notif.security_notification_id)
    end

    @feeds = LanguageFeed.by_language(@lang).map(&:url)
    render template: "languages/index"
  end
  
end
