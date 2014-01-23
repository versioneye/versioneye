require 'spec_helper'

describe VersionService do

  let( :product ) { Product.new }

  describe "newest_version" do

    it "returns the newest stable version" do
      product.versions.push( Version.new({:version => "1.0" }) )
      product.versions.push( Version.new({:version => "1.1" }) )
      newest = VersionService.newest_version( product.versions )
      newest.version.should eql("1.1")
    end

    it "returns the newest stable version" do
      product.versions.push( Version.new({:version => "1.0" }) )
      product.versions.push( Version.new({:version => "1.1-dev" }) )
      newest = VersionService.newest_version( product.versions )
      newest.version.should eql("1.0")
    end

    it "returns the newest dev version" do
      product.versions.push( Version.new({:version => "1.0" }) )
      product.versions.push( Version.new({:version => "1.1-dev" }) )
      newest = VersionService.newest_version( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      newest.version.should eql("1.1-dev")
    end

    it "returns the newest RC version" do
      product.versions.push( Version.new({:version => "3.2.13" }) )
      product.versions.push( Version.new({:version => "3.2.13.rc2" }) )
      newest = VersionService.newest_version( product.versions, VersionTagRecognizer::A_STABILITY_RC )
      newest.version.should eql("3.2.13")
    end

    it "returns the newest dev version because there is no stable" do
      product.versions.push( Version.new({:version => "1.0-Beta" }) )
      product.versions.push( Version.new({:version => "1.1-dev"  }) )
      newest = VersionService.newest_version( product.versions )
      newest.version.should eql("1.1-dev")
    end

    it "returns the newest dev version because the other one is dev-master" do
      product.versions.push( Version.new({:version => "dev-master" }) )
      product.versions.push( Version.new({:version => "1.1-dev"  }) )
      newest = VersionService.newest_version( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      newest.version.should eql("1.1-dev")
    end

    it "returns the dev-master because it is the only one" do
      product.versions.push( Version.new({:version => "dev-master" }) )
      newest = VersionService.newest_version( product.versions, VersionTagRecognizer::A_STABILITY_DEV )
      newest.version.should eql("dev-master")
    end

    it "returns the newest value from minor patches" do
      versions = []
      versions << Version.new(version: "2.0.1")
      versions << Version.new(version: "2.0.1-dev")
      versions << Version.new(version: "2.0.2-dev")
      versions << Version.new(version: "2.0.2")
      versions << Version.new(version: "2.0.3")
      versions << Version.new(version: "2.0.4")
      versions << Version.new(version: "2.0.4-dev")
      versions << Version.new(version: "2.0.5")
      versions << Version.new(version: "2.0.5-dev")

      newest = VersionService.newest_version(versions)
      newest.should_not be_nil
      newest[:version].should eq("2.0.5")
    end

  end

  describe "versions_by_whitelist" do
    before :each do
      product.versions = []
    end

    it "returns empty list when whitelist is nil" do
      product.versions << Version.new(version: "0.1")
      allowed_versions = VersionService.versions_by_whitelist(product.versions, nil)
      allowed_versions.should be_empty
    end

    it "returns empty list when whitelist is just empty array" do
      product.versions << Version.new(version: "0.1")
      allowed_versions = VersionService.versions_by_whitelist(product.versions, [])
      allowed_versions.should be_empty
    end

    it "returns empty list when whitelist has no matching versions" do
      product.versions << Version.new(version: "0.1")
      allowed_versions = VersionService.versions_by_whitelist(product.versions, ["2.0"])
      allowed_versions.should be_empty
    end

    it "returns correct version when whitelist has only one version" do
      product.versions << Version.new(version: "0.1")
      product.versions << Version.new(version: "0.2")
      product.versions << Version.new(version: "1.2")
      allowed_versions = VersionService.versions_by_whitelist(product.versions, ["0.2"])
      allowed_versions.should_not be_empty
      allowed_versions.first[:version].should eq("0.2")
    end

    it "returns correct versions when whitelist has many matching versions" do
      product.versions << Version.new(version: "0.1")
      product.versions << Version.new(version: "0.2")
      product.versions << Version.new(version: "1.2")
      allowed_versions = VersionService.versions_by_whitelist(product.versions, ["0.2", "1.0", "1.2"])
      
      allowed_versions.should_not be_empty
      allowed_versions.size.should eq(2)
      allowed_versions[0][:version].should eq("0.2")
      allowed_versions[1][:version].should eq("1.2")
    end


  end


  describe "newest_version_number" do

    it "returns the newest version correct." do
      product.versions = Array.new
      ver = 1
      5.times{
        version = Version.new
        version.version = ver.to_s
        ver += 1
        product.versions.push(version)
      }
      version = VersionService.newest_version_number( product.versions )
      version.should eql("5")
    end

    it "returns the newest version correct. With decimal numbers." do
      product.versions = Array.new
      ver = 1
      5.times{
        version = Version.new
        version.version = "1." + ver.to_s
        ver += 1
        product.versions.push(version)
      }
      version = VersionService.newest_version_number( product.versions )
      version.should eql("1.5")
    end

    it "returns the newest version correct. With long numbers." do
      product.versions = Array.new
      product.versions.push( Version.new({ :version => "1.2.2" }) )
      product.versions.push( Version.new({ :version => "1.2.29" }) )
      product.versions.push( Version.new({ :version => "1.3" }) )
      version = VersionService.newest_version_number( product.versions )
      version.should eql("1.3")
    end

    it "returns the newest version correct. With long numbers. Wariant 2." do
      product.versions = Array.new
      product.versions.push( Version.new({ :version => "1.22" }) )
      product.versions.push( Version.new({ :version => "1.229" }) )
      product.versions.push( Version.new({ :version => "1.30" }) )
      version = VersionService.newest_version_number( product.versions )
      version.should eql("1.229")
    end

  end

  describe "static newest_version_from" do

    it "returns the correct version" do
      versions = Array.new
      versions.push( Version.new({ :version => "1.22"  }) )
      versions.push( Version.new({ :version => "1.229" }) )
      versions.push( Version.new({ :version => "1.30"  }) )
      VersionService.newest_version_from(versions).version.should eql("1.229")
    end

  end

  describe "newest_version_from_wildcard" do
    it "returns newest version for 1.x" do
      versions = []
      versions << Version.new({version: "0.1"})
      versions << Version.new({version: "0.9"})
      versions << Version.new({version: "1.0"})
      versions << Version.new({version: "1.1"})
      versions << Version.new({version: "1.5"})
      versions << Version.new({version: "1.7"})

      newest = VersionService.newest_version_from_wildcard(versions, '1.*')
      newest.should_not be_nil
      newest.should eq("1.7")
    end

    it "returns newest version for 2.0.*" do
      versions = []
      versions << Version.new({version: "2.0.1"})
      versions << Version.new({version: "2.0.5"})
      versions << Version.new({version: "2.0.5-alpha"})
      versions << Version.new({version: "2.1.1"})

      newest = VersionService.newest_version_from_wildcard(versions, '2.0.x')
      newest.should_not be_nil
      newest.should eq('2.0.5')
    end
  end

  describe "version_approximately_greater_than_starter" do

    it "returns the given value" do
      VersionService.version_approximately_greater_than_starter("1.0").should eql("1.")
    end
    it "returns the given value" do
      VersionService.version_approximately_greater_than_starter("1.2").should eql("1.")
    end
    it "returns the given value" do
      VersionService.version_approximately_greater_than_starter("1.2.3").should eql("1.2.")
    end
  end


  describe "version_tilde_newest" do

    # TODO make it work with 1.345
    it "returns the right value" do
      product.versions = Array.new
      product.versions.push( Version.new({:version => "1.0"}) )
      product.versions.push( Version.new({:version => "1.1"}) )
      product.versions.push( Version.new({:version => "1.2"}) )
      product.versions.push( Version.new({:version => "1.3"}) )
      product.versions.push( Version.new({:version => "2.0"}) )
      tilde_version = VersionService.version_tilde_newest(product.versions, "1.2")
      tilde_version.version.should eql("1.3")
    end

    it "returns the right value" do
      product.versions = Array.new
      product.versions.push( Version.new({:version => "1.0"}) )
      product.versions.push( Version.new({:version => "1.2"}) )
      product.versions.push( Version.new({:version => "1.3"}) )
      product.versions.push( Version.new({:version => "1.4"}) )
      product.versions.push( Version.new({:version => "2.0"}) )
      tilde_version = VersionService.version_tilde_newest(product.versions, "1.2")
      tilde_version.version.should eql("1.4")
    end

    it "returns the right value" do
      product.versions = Array.new
      product.versions.push( Version.new({:version => "2.0.0"}) )
      product.versions.push( Version.new({:version => "2.2.0"}) )
      product.versions.push( Version.new({:version => "2.3.0"}) )
      product.versions.push( Version.new({:version => "2.3.1"}) )
      product.versions.push( Version.new({:version => "3.0.0"}) )
      tilde_version = VersionService.version_tilde_newest( product.versions, "~2.1" )
      tilde_version.version.should eql("2.3.1")
    end

    it "returns the right value" do
      product.versions = Array.new
      product.versions.push( Version.new({:version => "3.7.29"}) )
      product.versions.push( Version.new({:version => "3.0.0"}) )
      product.versions.push( Version.new({:version => "2.3.0"}) )
      product.versions.push( Version.new({:version => "2.3.1"}) )
      product.versions.push( Version.new({:version => "3.0.1"}) )
      tilde_version = VersionService.version_tilde_newest( product.versions, "~3.0" )
      tilde_version.version.should eql("3.7.29")
    end

    it "returns the right value" do
      product.versions = Array.new
      product.versions.push( Version.new({:version => "3.7.29"}) )
      product.versions.push( Version.new({:version => "3.0.0"}) )
      product.versions.push( Version.new({:version => "2.3.0"}) )
      product.versions.push( Version.new({:version => "2.3.1"}) )
      product.versions.push( Version.new({:version => "3.0.1"}) )
      tilde_version = VersionService.version_tilde_newest( product.versions, "~3" )
      tilde_version.version.should eql("3.7.29")
    end

  end

  describe "version_tilde_newest" do
    it "returns the right value 2.0.0" do
      VersionService.tile_border( "1.2" ).should eql("2.0")
    end
    it "returns the right value 2.0.0" do
      VersionService.tile_border( "1.2.1" ).should eql("1.3")
    end
    it "returns the right value 2.0.0" do
      VersionService.tile_border( "1.2.1-1" ).should eql("1.3")
    end
    it "returns the right value 2.0.0" do
      VersionService.tile_border( "1.2.1_1" ).should eql("1.3")
    end
    it "returns the right value 2.0.0" do
      VersionService.tile_border( "1.2.1_RC" ).should eql("1.3")
    end
  end

  describe "get_version_range" do

    it "returns the right range" do
      product.versions = Array.new
      product.versions.push( Version.new({ :version => "1.0" }) )
      product.versions.push( Version.new({ :version => "1.1" }) )
      product.versions.push( Version.new({ :version => "1.2" }) )
      product.versions.push( Version.new({ :version => "1.3" }) )
      product.versions.push( Version.new({ :version => "1.4" }) )

      range = VersionService.version_range(product.versions, "1.1", "1.3")
      range.count.should eql(3)
      range.first.version.should eql("1.1")
      range.last.version.should  eql("1.3")
    end

  end

  describe "versions_start_with" do

    it "returns an empty array" do
      VersionService.versions_start_with(nil, "1.0").should eql([])
    end

    it "returns the correct array" do
      product.versions.push( Version.new( { :version => "1.1" } ) )
      product.versions.push( Version.new( { :version => "1.2" } ) )
      product.versions.push( Version.new( { :version => "1.3" } ) )
      product.versions.push( Version.new( { :version => "2.0" } ) )
      results = VersionService.versions_start_with(product.versions, "1")
      results.size.should eql(3)
      results.first.version.should eql("1.1")
      results.last.version.should  eql("1.3")
      results = VersionService.versions_start_with(product.versions, "1.")
      results.size.should eql(3)
      results.first.version.should eql("1.1")
      results.last.version.should  eql("1.3")
    end

  end


  describe "versions_by_comperator" do
    let(:versions){[]}
    before :each do
      versions << Version.new(version: "1.1")
      versions << Version.new(version: "1.2")
      versions << Version.new(version: "1.3")
      versions << Version.new(version: "1.4")
      versions << Version.new(version: "1.7")
     end

    it "returns newest not equal version" do
      version = VersionService.versions_by_comperator(versions, "!=", "1.2", false)
      version.should_not be_nil
      version[:version].should eq("1.7")
    end

    it "returns right range for != operator" do     
      results = VersionService.versions_by_comperator(versions, "!=", "1.2", true)
      results.should_not be_nil
      results.size.should eq(4)

      results[0][:version].should eq("1.1")
      results[1][:version].should eq("1.3")
      results[2][:version].should eq("1.4")
      results[3][:version].should eq("1.7")
   end

    it "returns newest version for `<` operator" do
     
      result = VersionService.versions_by_comperator(versions, "<", "1.3", false)
      result.should_not be_nil
      result[:version].should eq("1.2")

      result = VersionService.versions_by_comperator(versions, "<", "1.5", false)
      result.should_not be_nil
      result[:version].should eq("1.4")

      result = VersionService.versions_by_comperator(versions, "<", "2.0", false)
      result.should_not be_nil
      result[:version].should eq("1.7")
    end

    it "returns correct versions range  for `<` operator" do     
      results = VersionService.versions_by_comperator(versions, "<", "1.3", true)
      results.should_not be_nil
      results.size.should eq(2)

      results[0][:version].should eq("1.1")
      results[1][:version].should eq("1.2")
   end

    it "returns newest version for `<=` operator" do
      result = VersionService.versions_by_comperator(versions, "<=", "1.4", false)
      result.should_not be_nil
      result[:version].should eq("1.4")
    end

    it "returns correct versions range for `<=` operator" do
      results = VersionService.versions_by_comperator(versions, "<=", "1.4", true)
      results.should_not be_nil
      results.size.should eq(4)
    end
    
    it "returns newest version for `>` operator" do
      result = VersionService.versions_by_comperator(versions, ">", "1.4", false)
      result.should_not be_nil
      result[:version].should eq("1.7")
    end

    it "returns correct versions range for `>` operator" do
      results = VersionService.versions_by_comperator(versions, ">", "1.4", true)
      results.should_not be_nil
      results.size.should eq(1)
    end

    it "returns newest version for `>=` operator" do
      result = VersionService.versions_by_comperator(versions, ">=", "1.4", false)
      result.should_not be_nil
      result[:version].should eq("1.7")
    end

    it "returns correct versions range for `>=` operator" do
      results = VersionService.versions_by_comperator(versions, ">=", "1.4", true)
      results.should_not be_nil
      results.size.should eq(2)
    end
  end

  describe "newest_but_not" do
    let(:versions){[]}
    before :each do
      versions << Version.new(version: "1.1")
      versions << Version.new(version: "1.2")
      versions << Version.new(version: "1.3")
    end

    it "returns the newest value except the one specific value" do
      result = VersionService.newest_but_not(versions, "1.3")
      result.should_not be_nil
      result[:version].should eq("1.2")
    end
  end

  describe "equal" do
    let(:versions){[]}
    before :each do
      versions << Version.new(version: "1.1")
      versions << Version.new(version: "1.2")
      versions << Version.new(version: "1.3")
    end

    it "returns correct version for the value" do
      result = VersionService.equal(versions, "1.1")
      result[:version].should eq("1.1")

      result = VersionService.equal(versions, "1.2")
      result[:version].should eq("1.2")

      result = VersionService.equal(versions, "1.3")
      result[:version].should eq("1.3")
    end
  end

  describe "not_equal" do
    let(:versions){[]}
    before :each do
      versions << Version.new(version: "1.1")
      versions << Version.new(version: "1.2")
      versions << Version.new(version: "1.3")
    end

    it "returns correct version for the value" do
      result = VersionService.not_equal(versions, "1.1")
      result[:version].should eq("1.3")

      result = VersionService.not_equal(versions, "1.2")
      result[:version].should eq("1.3")

      result = VersionService.not_equal(versions, "1.3")
      result[:version].should eq("1.2")
    end
  end

  describe "get_greater_than" do

    it "returns the highest value" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      product.versions.push( Version.new( { :version => "1.1" } ) )
      product.versions.push( Version.new( { :version => "1.2" } ) )
      ver = VersionService.greater_than(product.versions, "1.1")
      ver.version.should eql("1.2")
    end

  end


  describe "greater_than_or_equal" do

    it "returns the highest value" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      product.versions.push( Version.new( { :version => "1.1" } ) )
      product.versions.push( Version.new( { :version => "1.2" } ) )
      ver = VersionService.greater_than_or_equal(product.versions, "1.1")
      ver.version.should eql("1.2")
    end

    it "returns the highest value" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      product.versions.push( Version.new( { :version => "1.1" } ) )
      ver = VersionService.greater_than_or_equal(product.versions, "1.1")
      ver.version.should eql("1.1")
    end

  end


  describe "smaller_than" do

    it "returns the highest value" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      product.versions.push( Version.new( { :version => "1.1" } ) )
      product.versions.push( Version.new( { :version => "1.2" } ) )
      ver = VersionService.smaller_than(product.versions, "1.1")
      ver.version.should eql("1.0")
    end

    it "returns the highest value" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "2.2.2" } ) )
      product.versions.push( Version.new( { :version => "2.2.3" } ) )
      product.versions.push( Version.new( { :version => "2.3.0" } ) )
      ver = VersionService.smaller_than(product.versions, "2.4-dev")
      ver.version.should eql("2.3.0")
    end

  end


  describe "smaller_than_or_equal" do

    it "returns the highest value" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      product.versions.push( Version.new( { :version => "1.1" } ) )
      product.versions.push( Version.new( { :version => "1.2" } ) )
      ver = VersionService.smaller_than_or_equal(product.versions, "1.1")
      ver.version.should eql("1.1")
    end

    it "returns the highest value" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      ver = VersionService.smaller_than_or_equal(product.versions, "1.1")
      ver.version.should eql("1.0")
    end

  end


  describe "update_version_data" do

    it "returns the one" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0" } ) )
      VersionService.update_version_data( product )
      product.version.should eql("1.0")
    end

    it "returns the highest stable" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0"     } ) )
      product.versions.push( Version.new( { :version => "1.1"     } ) )
      product.versions.push( Version.new( { :version => "1.2-dev" } ) )
      VersionService.update_version_data( product )
      product.version.should eql("1.1")
    end

    it "returns the highest unststable because there is no stable" do
      product.versions = Array.new
      product.versions.push( Version.new( { :version => "1.0-beta" } ) )
      product.versions.push( Version.new( { :version => "1.1-beta" } ) )
      product.versions.push( Version.new( { :version => "1.2-dev"  } ) )
      VersionService.update_version_data( product )
      product.version.should eql("1.2-dev")
    end

  end


end
