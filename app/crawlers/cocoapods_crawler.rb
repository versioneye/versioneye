require 'gitcrawler'

class CocoaPodsCrawler < GitCrawler

  def initialize
    super "https://github.com/CocoaPods/Specs.git", "~/cocoapods-specs"
  end

  # traverse directory, search for .podspec files
  def spec_files
    Dir.glob "**/*.podspec" do |file|
      # parse every podspec file
      PodSpecParser.parse file
    end
  end

end