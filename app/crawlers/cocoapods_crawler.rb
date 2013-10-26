require 'gitcrawler'

class CocoaPodsCrawler < GitCrawler

  def initialize
    super "https://github.com/CocoaPods/Specs.git", "~/cocoapods-specs"
  end

  def crawl
    setup
    update
    all_spec_files do |filepath|
      # parse every podspec file
      product = PodSpecParser.new().parse filepath
      product.save
    end
  end

  # traverse directory, search for .podspec files
  def all_spec_files(&block)
    Dir.glob "**/*.podspec" do |filepath|
      block.call filepath
    end
  end

end