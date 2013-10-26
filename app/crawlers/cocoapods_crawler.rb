require 'gitcrawler'

class CocoaPodsCrawler < GitCrawler

  def initialize
    super "https://github.com/CocoaPods/Specs.git", "~/cocoapods-specs"
  end

  def crawl
    setup
    update
    parser = PodSpecParser.new
    all_spec_files do |filepath|
      # parse every podspec file
      product = parser.parse_file filepath
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
