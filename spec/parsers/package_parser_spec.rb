require 'spec_helper'

describe PackageParser do

  describe "parse" do

    it "parse from https the file correctly" do
      parser = PackageParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/package.json")
      project.should_not be_nil
    end

    it "parse from http the file correctly" do
      name1 = "connect-redis"
      product1 = Product.new
      product1.name = name1
      product1.name_downcase = name1
      product1.prod_key = "connect-redis"
      product1.language = Product::A_LANGUAGE_NODEJS
      product1.version = "1.3.0"
      product1.save
      version1_1 = Version.new
      version1_1.version = "1.3.0"
      product1.versions.push(version1_1)
      product1.save

      name2 = "redis"
      product2 = Product.new
      product2.name = name2
      product2.name_downcase = name2
      product2.prod_key = "redis"
      product2.language = Product::A_LANGUAGE_NODEJS
      product2.version = "1.3.0"
      product2.save
      version2_1 = Version.new
      version2_1.version = "1.3.0"
      product2.versions.push(version2_1)
      product2.save

      name3 = "memcache"
      product3 = Product.new
      product3.name = name3
      product3.name_downcase = "memcache"
      product3.prod_key = "memcache"
      product3.language = Product::A_LANGUAGE_NODEJS
      product3.version = "1.4.0"
      product3.save
      version3_1 = Version.new
      version3_1.version = "1.4.0"
      product3.versions.push(version3_1)
      product3.save

      name4 = "mongo"
      product4 = Product.new
      product4.name = name4
      product4.name_downcase = name4
      product4.prod_key = "mongo"
      product4.language = Product::A_LANGUAGE_NODEJS
      product4.version = "1.1.7"
      product4.save
      version4_1 = Version.new
      version4_1.version = "1.1.7"
      product4.versions.push(version4_1)
      product4.save

      name5 = "mongoid"
      product5 = Product.new
      product5.name = name5
      product5.name_downcase = name5
      product5.prod_key = "mongoid"
      product5.language = Product::A_LANGUAGE_NODEJS
      product5.version = "1.1.7"
      product5.save
      version5_1 = Version.new
      version5_1.version = "1.1.7"
      product5.versions.push(version5_1)
      product5.save

      name6 = "express"
      product6 = Product.new
      product6.name = name6
      product6.name_downcase = name6
      product6.prod_key = "express"
      product6.language = Product::A_LANGUAGE_NODEJS
      product6.version = "2.4.7"
      product6.save
      version6_1 = Version.new
      version6_1.version = "2.4.0"
      product6.versions.push(version6_1)
      version6_2 = Version.new
      version6_2.version = "2.4.6"
      product6.versions.push(version6_2)
      version6_3 = Version.new
      version6_3.version = "2.4.7"
      product6.versions.push(version6_3)
      product6.save

      name7 = "fs-ext"
      product7 = Product.new
      product7.name = name7
      product7.name_downcase = name7
      product7.prod_key = "fs-ext"
      product7.language = Product::A_LANGUAGE_NODEJS
      product7.version = "2.4.7"
      product7.save
      version7_1 = Version.new
      version7_1.version = "0.2.0"
      product7.versions.push(version7_1)
      version7_2 = Version.new
      version7_2.version = "0.2.7"
      product7.versions.push(version7_2)
      version7_3 = Version.new
      version7_3.version = "2.4.7"
      product7.versions.push(version7_3)
      product7.save

      name8 = "jade"
      product8 = Product.new
      product8.name = name8
      product8.name_downcase = name8
      product8.prod_key = "jade"
      product8.language = Product::A_LANGUAGE_NODEJS
      product8.version = "2.4.7"
      product8.save
      version8_1 = Version.new
      version8_1.version = "0.2.0"
      product8.versions.push(version8_1)
      version8_2 = Version.new
      version8_2.version = "0.2.7"
      product8.versions.push(version8_2)
      version8_3 = Version.new
      version8_3.version = "2.4.7"
      product8.versions.push(version8_3)
      product8.save

      name9 = "mailer"
      product9 = Product.new
      product9.name = name9
      product9.name_downcase = name9
      product9.prod_key = "mailer"
      product9.language = Product::A_LANGUAGE_NODEJS
      product9.version = "0.7.0"
      product9.save
      version9_1 = Version.new
      version9_1.version = "0.6.0"
      product9.versions.push(version9_1)
      version9_2 = Version.new
      version9_2.version = "0.6.1"
      product9.versions.push(version9_2)
      version9_3 = Version.new
      version9_3.version = "0.6.5"
      product9.versions.push(version9_3)
      version9_4 = Version.new
      version9_4.version = "0.6.9"
      product9.versions.push(version9_4)
      version9_5 = Version.new
      version9_5.version = "0.7.0"
      product9.versions.push(version9_5)
      product9.save

      name10 = "markdown"
      product10 = Product.new
      product10.name = name10
      product10.name_downcase = name10
      product10.prod_key = "markdown"
      product10.language = Product::A_LANGUAGE_NODEJS
      product10.version = "0.4.0"
      product10.save
      version10_1 = Version.new
      version10_1.version = "0.2.0"
      product10.versions.push(version10_1)
      version10_2 = Version.new
      version10_2.version = "0.3.0"
      product10.versions.push(version10_2)
      version10_3 = Version.new
      version10_3.version = "0.4.0"
      product10.versions.push(version10_3)
      product10.save

      name11 = "mu2"
      product11 = Product.new
      product11.name = name11
      product11.name_downcase = name11
      product11.prod_key = "mu2"
      product11.language = Product::A_LANGUAGE_NODEJS
      product11.version = "0.6.0"
      product11.save
      version11_1 = Version.new
      version11_1.version = "0.5.10"
      product11.versions.push(version11_1)
      version11_2 = Version.new
      version11_2.version = "0.5.0"
      product11.versions.push(version11_2)
      version11_3 = Version.new
      version11_3.version = "0.6.0"
      product11.versions.push(version11_3)
      product11.save

      name12 = "pg"
      product12 = Product.new
      product12.name = name12
      product12.name_downcase = name12
      product12.prod_key = "pg"
      product12.language = Product::A_LANGUAGE_NODEJS
      product12.version = "0.6.6"
      product12.save
      version12_1 = Version.new
      version12_1.version = "0.6.6"
      product12.versions.push(version12_1)
      version12_2 = Version.new
      version12_2.version = "0.5.0"
      product12.versions.push(version12_2)
      version12_3 = Version.new
      version12_3.version = "0.6.1"
      product12.versions.push(version12_3)
      product12.save

      name13 = "pg_connect"
      product13 = Product.new
      product13.name = name13
      product13.name_downcase = name13
      product13.prod_key = "pg_connect"
      product13.language = Product::A_LANGUAGE_NODEJS
      product13.version = "0.6.9"
      product13.save
      version13_1 = Version.new
      version13_1.version = "0.6.9"
      product13.versions.push(version13_1)
      version13_2 = Version.new
      version13_2.version = "0.5.0"
      product13.versions.push(version13_2)
      version13_3 = Version.new
      version13_3.version = "0.6.1"
      product13.versions.push(version13_3)
      product13.save


      parser = PackageParser.new
      project = parser.parse("http://s3.amazonaws.com/veye_test_env/package.json")
      project.should_not be_nil
      project.dependencies.size.should eql(14)

      dep_01 = project.dependencies.first
      dep_01.name.should eql("connect-redis")
      dep_01.version_requested.should eql("1.3.0")
      dep_01.version_current.should eql("1.3.0")
      dep_01.comperator.should eql("=")

      dep_02 = project.dependencies[1]
      dep_02.name.should eql("redis")
      dep_02.version_requested.should eql("1.3.0")
      dep_02.version_current.should eql("1.3.0")
      dep_02.comperator.should eql("=")

      dep_03 = project.dependencies[2]
      dep_03.name.should eql("memcache")
      dep_03.version_requested.should eql("1.4.0")
      dep_03.version_current.should eql("1.4.0")
      dep_03.comperator.should eql("=")

      dep_04 = project.dependencies[3]
      dep_04.name.should eql("mongo")
      dep_04.version_requested.should eql("1.1.7")
      dep_04.version_current.should eql("1.1.7")
      dep_04.comperator.should eql("=")

      dep_05 = project.dependencies[4]
      dep_05.name.should eql("mongoid")
      dep_05.version_requested.should eql("1.1.7")
      dep_05.version_current.should eql("1.1.7")
      dep_05.comperator.should eql("=")

      dep_06 = project.dependencies[5]
      dep_06.name.should eql("express")
      dep_06.version_requested.should eql("2.4.7")
      dep_06.version_current.should eql("2.4.7")
      dep_06.comperator.should eql("=")

      dep_07 = project.dependencies[6]
      dep_07.name.should eql("fs-ext")
      dep_07.version_requested.should eql("0.2.7")
      dep_07.version_current.should eql("2.4.7")
      dep_07.comperator.should eql("=")

      dep_08 = project.dependencies[7]
      dep_08.name.should eql("jade")
      dep_08.version_requested.should eql("0.2.7")
      dep_08.version_current.should eql("2.4.7")
      dep_08.comperator.should eql("~")

      dep_09 = project.dependencies[8]
      dep_09.name.should eql("mailer")
      dep_09.version_requested.should eql("0.6.9")
      dep_09.version_current.should eql("0.7.0")
      dep_09.comperator.should eql("=")

      dep_10 = project.dependencies[9]
      dep_10.name.should eql("markdown")
      dep_10.version_requested.should eql("0.2.0")
      dep_10.version_current.should eql("0.4.0")
      dep_10.comperator.should eql("<")

      dep_11 = project.dependencies[10]
      dep_11.name.should eql("mu2")
      dep_11.version_requested.should eql("0.6.0")
      dep_11.version_current.should eql("0.6.0")
      dep_11.comperator.should eql(">")

      dep_12 = project.dependencies[11]
      dep_12.name.should eql("pg")
      dep_12.version_requested.should eql("0.6.6")
      dep_12.version_current.should eql("0.6.6")
      dep_12.comperator.should eql(">=")

      dep_13 = project.dependencies[12]
      dep_13.name.should eql("pg_connect")
      dep_13.version_requested.should eql("0.6.9")
      dep_13.version_current.should eql("0.6.9")
      dep_13.comperator.should eql("<=")

      product1.remove
      product2.remove
      product3.remove
      product4.remove
      product5.remove
      product6.remove
      product7.remove
      product8.remove
      product9.remove
      product10.remove
      product11.remove
      product12.remove
      product13.remove
    end

  end

end
