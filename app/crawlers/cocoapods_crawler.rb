require 'git_crawler'

class CocoapodsCrawler < GitCrawler

  def self.crawl
    self.new.crawl
  end

  def initialize
    # TODO put config in config file
    super "https://github.com/CocoaPods/Specs.git", "/Users/anjaresmer/cocoapods-specs"
  end

  def crawl
    setup
    update

    i = 0
    all_spec_files do |filepath|
      # parse every podspec file
      i += 1
      Rails.logger.info "Parse CocoaPods Spec ##{i}: #{filepath}"
      parser  = CocoapodsPodspecParser.new
      product = parser.parse_file filepath
      if product
        product.save
      else
        Rails.logger.warn "NO PRODUCT"
      end
    end

  end

  # traverse directory, search for .podspec files
  def all_spec_files(&block)
    Dir.glob "#{@dir}/**/*.podspec" do |filepath|
      block.call filepath
    end
  end

end
