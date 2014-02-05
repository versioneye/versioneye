require 'spec_helper'

describe PackageParser do

  before(:each) do
    Product.destroy_all
  end

  after(:each) do
    Product.destroy_all
  end

  describe "parse" do

    it "parse from https the file correctly" do
      parser = PackageParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/package_run_dev.json")
      project.should_not be_nil
    end

    it "parse from http the file correctly" do
      product1  = create_product('connect-redis', 'connect-redis', '1.3.0')
      product2  = create_product('redis'        , 'redis'     , '1.3.0')
      product3  = create_product('memcache'     , 'memcache'  , '1.4.0')
      product4  = create_product('mongo'        , 'mongo'     , '1.1.7')
      product5  = create_product('mongoid'      , 'mongoid'   , '1.1.7')
      product6  = create_product('express'      , 'express'   , '2.4.7', ['2.4.0' , '2.4.6', '2.4.7' ] )
      product7  = create_product('fs-ext'       , 'fs-ext'    , '2.4.7', ['0.2.0' , '0.2.7', '2.4.7' ] )
      product8  = create_product('jade'         , 'jade'      , '2.4.7', ['0.2.0' , '0.2.7', '2.4.7' ] )
      product9  = create_product('mailer'       , 'mailer'    , '0.7.0', ['0.6.0' , '0.6.1', '0.6.5', '0.6.9', '0.7.0'])
      product10 = create_product('markdown'     , 'markdown'  , '0.4.0', ['0.2.0' , '0.3.0', '0.4.0' ] )
      product11 = create_product('mu2'          , 'mu2'       , '0.6.0', ['0.5.10', '0.5.0', '0.6.0' ] )
      product12 = create_product('pg'           , 'pg'        , '0.6.6', ['0.5.0' , '0.6.1' ] )
      product13 = create_product('pg_connect'   , 'pg_connect', '0.6.9', ['0.5.0' , '0.6.1' ] )

      parser = PackageParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/package_run_dev.json")
      project.should_not be_nil
      project.dependencies.size.should eql(13)

      dep_01 = project.dependencies.first
      dep_01.name.should eql("connect-redis")
      dep_01.version_requested.should eql("1.3.0")
      dep_01.version_current.should eql("1.3.0")
      dep_01.comperator.should eql("=")

      dep_03 = project.dependencies[1]
      dep_03.name.should eql("memcache")
      dep_03.version_requested.should eql("1.4.0")
      dep_03.version_current.should eql("1.4.0")
      dep_03.comperator.should eql("=")

      dep_04 = project.dependencies[2]
      dep_04.name.should eql("mongo")
      dep_04.version_requested.should eql("1.1.7")
      dep_04.version_current.should eql("1.1.7")
      dep_04.comperator.should eql("=")

      dep_05 = project.dependencies[3]
      dep_05.name.should eql("mongoid")
      dep_05.version_requested.should eql("1.1.7")
      dep_05.version_current.should eql("1.1.7")
      dep_05.comperator.should eql("=")

      dep_06 = project.dependencies[4]
      dep_06.name.should eql("express")
      dep_06.version_requested.should eql("2.4.7")
      dep_06.version_current.should eql("2.4.7")
      dep_06.comperator.should eql("=")

      dep_07 = project.dependencies[5]
      dep_07.name.should eql("fs-ext")
      dep_07.version_requested.should eql("0.2.7")
      dep_07.version_current.should eql("2.4.7")
      dep_07.comperator.should eql("=")

      dep_08 = project.dependencies[6]
      dep_08.name.should eql("jade")
      dep_08.version_requested.should eql("0.2.7")
      dep_08.version_current.should eql("2.4.7")
      dep_08.comperator.should eql("~")

      dep_09 = project.dependencies[7]
      dep_09.name.should eql("mailer")
      dep_09.version_requested.should eql("0.6.9")
      dep_09.version_current.should eql("0.7.0")
      dep_09.comperator.should eql("=")

      dep_10 = project.dependencies[8]
      dep_10.name.should eql("markdown")
      dep_10.version_requested.should eql("0.2.0")
      dep_10.version_current.should eql("0.4.0")
      dep_10.comperator.should eql("<")

      dep_11 = project.dependencies[9]
      dep_11.name.should eql("mu2")
      dep_11.version_requested.should eql("0.6.0")
      dep_11.version_current.should eql("0.6.0")
      dep_11.comperator.should eql(">")

      dep_12 = project.dependencies[10]
      dep_12.name.should eql("pg")
      dep_12.version_requested.should eql("0.6.6")
      dep_12.version_current.should eql("0.6.6")
      dep_12.comperator.should eql(">=")

      dep_13 = project.dependencies[11]
      dep_13.name.should eql("pg_connect")
      dep_13.version_requested.should eql("0.6.9")
      dep_13.version_current.should eql("0.6.9")
      dep_13.comperator.should eql("<=")

      dep_02 = project.dependencies[12]
      dep_02.name.should eql("redis")
      dep_02.version_requested.should eql("1.3.0")
      dep_02.version_current.should eql("1.3.0")
      dep_02.comperator.should eql("=")

    end

  end

  def create_product(name, prod_key, version, versions = nil )
    product = Product.new({ :language => Product::A_LANGUAGE_NODEJS, :prod_type => Project::A_TYPE_NPM })
    product.name = name
    product.prod_key = prod_key
    product.version = version
    product.add_version( version )
    product.save

    return product if !versions

    versions.each do |ver|
      product.add_version( ver )
    end
    product.save

    product
  end

end
