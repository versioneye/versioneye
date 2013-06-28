namespace :languagefeed do
  desc "initializes collection of languagefeed. 
  PS: it cleans collection before adding. For language name check Product model"
  task :init => :environment do
    newsfeeds = [
      {
        language: "Ruby",
        title: "Ruby language news",
        url: "http://www.ruby-lang.org/en/feeds/news.rss"
      },
      {
        language: "Ruby",
        title: "Ruby Insider",
        url: "http://www.rubyinside.com/feed/"
      }
    ]
    LanguageFeed.delete_all
    newsfeeds.each do |feed|
      LanguageFeed.new(feed).save
    end

  end

end
