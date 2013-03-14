require 'spec_helper'

describe Product do
  
  describe "newest_version" do
    
    it 'delivers dev' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.7")
      version_01 = Version.new 
      version_01.version = "2.0.6"
      product.versions.push( version_01 )
      product.save    

      version = product.newest_version( Projectdependency::A_STABILITY_DEV )
      version.should eql("2.0.7")
      version = product.newest_version( Projectdependency::A_STABILITY_ALPHA )
      version.should eql("2.0.7")
      version = product.newest_version( Projectdependency::A_STABILITY_BETA )
      version.should eql("2.0.7")
      version = product.newest_version( Projectdependency::A_STABILITY_RC )
      version.should eql("2.0.7")
      version = product.newest_version( Projectdependency::A_STABILITY_STABLE )
      version.should eql("2.0.7")
    end

    it 'delivers the right thing' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      version_01 = Version.new 
      version_01.version = "2.0.6"
      product.versions.push( version_01 )
      product.save    

      version = product.newest_version( Projectdependency::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = product.newest_version( Projectdependency::A_STABILITY_ALPHA )
      version.should eql("2.0.6")
      version = product.newest_version( Projectdependency::A_STABILITY_BETA )
      version.should eql("2.0.6")
      version = product.newest_version( Projectdependency::A_STABILITY_RC )
      version.should eql("2.0.6")
      version = product.newest_version( Projectdependency::A_STABILITY_STABLE )
      version.should eql("2.0.6")
    end

    it 'delivers alpha ' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      version_01 = Version.new 
      version_01.version = "2.0.1-alpha0"
      product.versions.push( version_01 )
      version_02 = Version.new 
      version_02.version = "1.9.1"
      product.versions.push( version_02 )
      product.save    

      version = product.newest_version( Projectdependency::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = product.newest_version( Projectdependency::A_STABILITY_ALPHA )
      version.should eql("2.0.1-alpha0")
    end

    it 'delivers beta' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      version_01 = Version.new 
      version_01.version = "2.0.1-alpha0"
      product.versions.push( version_01 )
      version_02 = Version.new 
      version_02.version = "1.9.1"
      product.versions.push( version_02 )
      version_03 = Version.new 
      version_03.version = "2.0.1-BETA"
      product.versions.push( version_03 )
      product.save    

      version = product.newest_version( Projectdependency::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = product.newest_version( Projectdependency::A_STABILITY_BETA )
      version.should eql("2.0.1-BETA")
    end

    it 'delivers RC' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      version_01 = Version.new 
      version_01.version = "2.0.1-alpha0"
      product.versions.push( version_01 )
      version_02 = Version.new 
      version_02.version = "1.9.1"
      product.versions.push( version_02 )
      version_03 = Version.new 
      version_03.version = "2.0.1-BETA"
      product.versions.push( version_03 )
      version_04 = Version.new 
      version_04.version = "2.0.1-RC"
      product.versions.push( version_04 )
      product.save    

      version = product.newest_version( Projectdependency::A_STABILITY_DEV )
      version.should eql("2.0.x-dev")
      version = product.newest_version( Projectdependency::A_STABILITY_RC )
      version.should eql("2.0.1-RC")
    end

    it 'delivers RC' do
      product = ProductFactory.create_for_composer("symfony/pojo", "2.0.x-dev")
      version_01 = Version.new 
      version_01.version = "2.0.1-alpha0"
      product.versions.push( version_01 )
      version_02 = Version.new 
      version_02.version = "1.9.1"
      product.versions.push( version_02 )
      version_03 = Version.new 
      version_03.version = "2.0.1-BETA"
      product.versions.push( version_03 )
      version_04 = Version.new 
      version_04.version = "2.0.1-RC"
      product.versions.push( version_04 )
      version_05 = Version.new 
      version_05.version = "2.0.1"
      product.versions.push( version_05 )
      product.save    

      version = product.newest_version( Projectdependency::A_STABILITY_STABLE )
      version.should eql("2.0.1")
    end
    
  end

end
