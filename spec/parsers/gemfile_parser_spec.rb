require 'spec_helper'

describe GemfileParser do
  
  describe "parse" do 
    
    it "parse from https the file correctly" do
      project = GemfileParser.parse("https://s3.amazonaws.com/veye_test_env/Gemfile")
      project.should_not be_nil
    end
    
    it "parse from http the file correctly" do
      name = "execjs"
      product = Product.new
      product.name = name
      product.name_downcase = name
      product.prod_key = name
      product.version = "1.4.0"
      product.save
      version1 = Version.new
      version1.version = "1.4.0"
      product.versions.push(version1)
      version2 = Version.new
      version2.version = "1.3.0"
      product.versions.push(version2)
      product.save

      name2 = "jquery-rails"
      product2 = Product.new
      product2.name = name2
      product2.name_downcase = name2
      product2.prod_key = name2
      product2.save
      version2_1 = Version.new
      version2_1.version = "1.0.0"
      product2.versions.push(version2_1)
      product2.version = "1.0.0"
      product2.save

      name3 = "therubyracer"
      product3 = Product.new
      product3.name = name3
      product3.name_downcase = name3
      product3.prod_key = "therubyracer"
      product3.version = "0.11.3"
      product3.save
      version3 = Version.new
      version3.version = "0.10.1"
      product3.versions.push(version3)
      version4 = Version.new
      version4.version = "0.11.3"
      product3.versions.push(version4)
      product3.save

      name4 = "will_paginate"
      product4 = Product.new
      product4.name = name4
      product4.name_downcase = name4
      product4.prod_key = "will_paginate"
      product4.version = "4.0.3"
      product4.save
      version4_1 = Version.new
      version4_1.version = "3.0.3"
      product4.versions.push(version4_1)
      version4_2 = Version.new
      version4_2.version = "4.0.3"
      product4.versions.push(version4_2)
      product4.save

      name5 = "gravatar_image_tag"
      product5 = Product.new
      product5.name = name5
      product5.name_downcase = name5
      product5.prod_key = "gravatar_image_tag"
      product5.version = "1.1.6"
      product5.save
      version5_1 = Version.new
      version5_1.version = "1.1.3"
      product5.versions.push(version5_1)
      version5_2 = Version.new
      version5_2.version = "1.1.6"
      product5.versions.push(version5_2)
      product5.save

      name6 = "tire"
      product6 = Product.new
      product6.name = name6
      product6.name_downcase = name6
      product6.prod_key = name6
      product6.version = "3.2.5"
      product6.save
      version6_1 = Version.new
      version6_1.version = "3.2.5"
      product6.versions.push(version6_1)
      product6.save

      name7 = "sass-rails"
      product7 = Product.new
      product7.name = name7
      product7.name_downcase = name7
      product7.prod_key = "sass-rails"
      product7.save
      version7_1 = Version.new
      version7_1.version = "3.2.5"
      product7.versions.push(version7_1)
      version7_2 = Version.new
      version7_2.version = "3.2.9"
      product7.versions.push(version7_2)
      version7_3 = Version.new
      version7_3.version = "3.3.9"
      product7.versions.push(version7_3)
      product7.version = "3.3.9"
      product7.save

      name8 = "sassy"
      product8 = Product.new
      product8.name = name7
      product8.name_downcase = name8
      product8.prod_key = "sassy"
      product8.version = "3.3.9"
      product8.save
      version8_1 = Version.new
      version8_1.version = "3.2.5"
      product8.versions.push(version8_1)
      version8_2 = Version.new
      version8_2.version = "3.2.9"
      product8.versions.push(version8_2)
      version8_3 = Version.new
      version8_3.version = "3.3.9"
      product8.versions.push(version8_3)
      product8.save

      project = GemfileParser.parse("http://s3.amazonaws.com/veye_test_env/Gemfile")
      project.should_not be_nil
      project.dependencies.count.should eql(8)
      
      dep_1 = project.dependencies.first
      dep_1.name.should eql("rails")
      dep_1.version_requested.should eql("3.2.6")
      dep_1.comperator.should eql("=")

      dep_2 = project.dependencies[1]
      dep_2.name.should eql("jquery-rails")
      dep_2.version_requested.should eql("1.0.0")
      dep_2.version_current.should eql("1.0.0")
      dep_2.comperator.should eql("=")

      dep_3 = project.dependencies[2]
      dep_3.name.should eql("execjs")
      dep_3.version_requested.should eql("1.3.0")
      dep_3.version_current.should eql("1.4.0")
      dep_3.version_label.should eql("1.4.0")
      dep_3.comperator.should eql("<")

      dep_4 = project.dependencies[3]
      dep_4.name.should eql("therubyracer")
      dep_4.version_requested.should eql("0.11.3")
      dep_4.version_current.should eql("0.11.3")
      dep_4.version_label.should eql("0.10.1")
      dep_4.comperator.should eql(">")

      dep_5 = project.dependencies[4]
      dep_5.name.should eql("will_paginate")
      dep_5.version_requested.should eql("3.0.3")
      dep_5.version_current.should eql("4.0.3")
      dep_5.version_label.should eql("3.0.3")
      dep_5.comperator.should eql("<=")

      dep_6 = project.dependencies[5]
      dep_6.name.should eql("gravatar_image_tag")
      dep_6.version_requested.should eql("1.1.6")
      dep_6.version_current.should eql("1.1.6")
      dep_6.version_label.should eql("1.1.3")
      dep_6.comperator.should eql(">=")

      dep_7 = project.dependencies[6]
      dep_7.name.should eql("sassy")
      dep_7.version_requested.should eql("3.2.9")
      dep_7.version_current.should eql("3.3.9")
      dep_7.version_label.should eql("3.2.0")
      dep_7.comperator.should eql("~>")

      dep_last = project.dependencies.last
      dep_last.name.should eql("sass-rails")
      dep_last.version_requested.should eql("3.2.9")
      dep_last.version_current.should eql("3.3.9")
      dep_last.comperator.should eql("~>")

      product.remove
      product2.remove
      product3.remove
      product4.remove
      product5.remove
      product6.remove
      product7.remove
      product8.remove
    end
    
  end
  
end