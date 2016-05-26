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
        language: "Clojure",
        title: "Clojure releases",
        url: "https://github.com/clojure/clojure/commits/master.atom"
      },
      {
        language: "PHP",
        title: "PHP release feed",
        url:  "http://www.php.net/releases.atom"
      },
      {
        language: "Node.JS",
        title: "Node.JS official announcements",
        url: "http://feeds.feedburner.com/nodejs/123123123"
      },
      {
        language: "Python",
        title: "Python news",
        url: "http://python.org/channews.rdf"
      },
      {
        language: "Java",
        title: "Java news",
        url: ""
      },
      {
        language: "Javascript",
        title: "Javascript news",
        url: "http://feeds.feedburner.com/nodejs/123123123"
      },
      {
        language: "R",
        title: "R news",
        url: "http://developer.r-project.org/blosxom.cgi/R-devel/NEWS/index.rss"
      }
    ]
    LanguageFeed.delete_all
    newsfeeds.each do |feed|
      LanguageFeed.new(feed).save
    end

  end

end
