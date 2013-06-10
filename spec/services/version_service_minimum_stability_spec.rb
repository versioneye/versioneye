require 'spec_helper'

# https://igor.io/2013/02/07/composer-stability-flags.html
#
describe VersionService do

  describe "newest_version_number" do

    it 'delivers dev' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.7")
      version_01 = Version.new
      version_01.version = "2.0.6"
      product.versions.push( version_01 )
      product.save
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      version.should eql("2.0.7")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_ALPHA )
      version.should eql("2.0.7")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_BETA )
      version.should eql("2.0.7")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_RC )
      version.should eql("2.0.7")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_STABLE )
      version.should eql("2.0.7")
    end

    it 'delivers the right thing' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      version_01 = Version.new
      version_01.version = "2.0.6"
      product.versions.push( version_01 )
      product.save
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_ALPHA )
      version.should eql("2.0.6")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_BETA )
      version.should eql("2.0.6")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_RC )
      version.should eql("2.0.6")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_STABLE )
      version.should eql("2.0.6")
    end

    it 'delivers alpha ' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      product.versions.push( Version.new({:version => "2.0.1-alpha0"}) )
      product.versions.push( Version.new({:version => "1.9.1"       }) )
      product.save
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_ALPHA )
      version.should eql("2.0.1-alpha0")
    end

    it 'delivers beta' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      product.versions.push( Version.new({:version => "2.0.1-alpha0"}) )
      product.versions.push( Version.new({:version => "1.9.1"       }) )
      product.versions.push( Version.new({:version => "2.0.1-BETA"  }) )
      product.save
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_BETA )
      version.should eql("2.0.1-BETA")
    end

    it 'delivers RC' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      product.versions.push( Version.new({:version => "2.0.1-alpha0"}) )
      product.versions.push( Version.new({:version => "1.9.1"       }) )
      product.versions.push( Version.new({:version => "2.0.1-BETA"  }) )
      product.versions.push( Version.new({:version => "2.0.1-RC"    }) )
      product.save
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_RC )
      version.should eql("2.0.1-RC")
    end

    it 'delivers RC' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      product.versions.push( Version.new({:version => "2.0.1-alpha0"}) )
      product.versions.push( Version.new({:version => "1.9.1"       }) )
      product.versions.push( Version.new({:version => "2.0.1-BETA"  }) )
      product.versions.push( Version.new({:version => "2.0.1-RC"    }) )
      product.versions.push( Version.new({:version => "2.0.1"       }) )
      product.save
      version = VersionService.newest_version_number( product.versions, VersionTagRecognizer::A_STABILITY_STABLE )
      version.should eql("2.0.1")
    end

  end

end
