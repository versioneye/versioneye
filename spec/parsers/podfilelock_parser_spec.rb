require 'spec_helper'

describe PodfilelockParser do

  def cocoa_product(product_name, latest_version, *other_versions)
    new_product = ProductFactory.create_for_cocoapods(product_name, latest_version)
    other_versions.each do |a_version|
      next if a_version.to_s.empty?
      new_product.versions.push(Version.new({:version => a_version}))
    end
    new_product.save
    new_product
  end


  describe '#parse' do

    it "should HTTP-get a lockfile and return a project with dependencies" do
      # project =
    end

  end

  describe '#parse_file' do

    def create_products
      cocoa_product("Masonry", "0.3.0",  "0.2.4",  "0.2.3")
      cocoa_product("RestKit", "0.22.0", "0.20.3", "0.10.3")
      cocoa_product("UIColor-Utilities", "1.0.1",  "1.0")
      cocoa_product("CupertinoYankee",   "1.0.0",  "0.1.1", "0.1")
      cocoa_product("MSCollectionViewCalendarLayout", "1.0")
    end

    it "should read a lockfile from disk and return a project with dependencies" do
      project = PodfilelockParser.new.parse_file 'spec/fixtures/files/podfilelock/example1/Podfile.lock'
    end

  end

end
