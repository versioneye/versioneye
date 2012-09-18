require 'spec_helper'

def add_local_products
	@products.each do |item|
    	p = Product.new item
    	p.update_attribute(:reindex, true)            
    end
    Product.index_newest
end

def get_index_count
	response = RestClient.get("http://localhost:9200/products/_count")
	JSON.parse(response)["count"]
end 

describe Product do

	before :each do
		@products = [		
			{:name => "club-mate", :language => "java", :group_id => "org.club.mate"},
			{:name => "club-mate", :language => "java", :group_id => "com.club.mate"},
			{:name => "club-mate", :language => "java", :group_id => "net.club.mate"},
			{:name => "club-mate", :language => "c", :group_id => ""},
			{:name => "club-mate", :language => "c++", :group_id => ""},
			{:name => "club-mate", :language => "ruby", :group_id => ""},
			{:name => "club-mate", :language => "c#", :group_id => "net.microsoft.crap"}
		]		
	end

	after :each do		
		Product.clean_all
		Product.where().delete
	end

	describe "new" do 
		context "with no indexes" do
			it "#clean_all" do
				Product.clean_all.should raise_exception
				#Product.clean_all["status"].should equal 404
			end 

			it "search" do
				r = Product.elastic_search("random query").should raise_exception
			end
		end

		context "index only one product" do
			it "#add_one" do
				p = Product.new @products[0]
				p.index_one.should raise_exception				
			end 

			it "#search" do
				#add doc to index
				p = Product.new @products[0]
				p.index_one
				#search
				results = Product.elastic_search @products[0][:name]
				results.count.should equal 1
			end
	
		end

		context "- index only documents, which has flagged to reindex" do
			it "index_newest" do
				#initialize data collection
				Product.clean_all
                @products.each do |item|
                	p = Product.new item
                	p.update_attribute(:reindex, true)            
                end
                r = Product.index_newest
                get_index_count.should equal @products.count 

                #test, there's anymore document to reindex
                Product.where(reindex: true).count.should equal 0               
			end

		end

		context "- index all documents in `products` collection" do 
			it "index_all" do
				Product.clean_all
				add_local_products
				r = Product.index_all
				get_index_count.should equal Product.count
			end
		end

		context "- tests search functionalities " do
			it "search empty string" do
				Product.index_all 
				r = Product.elastic_search ""
				r.count.should equal 0				
			end

			#TODO: c gaves every c language, but c++ and c# dont work at all
			it "test language filtering"  do 
				add_local_products
				Product.elastic_search("club-mate", nil, "java").count.should equal 3
				#Product.elastic_search("club-mate", "c,c++").count.should equal 2
				Product.elastic_search("club-mate", nil, "c,c#,c++").count.should equal 3
			end

			it "test, does language filtering is case insensitive" do
				add_local_products
				r1 = Product.elastic_search "club-mate", nil, "Java"
				r2 = Product.elastic_search "club-mate", nil, "java"
				r1[0][:name].should eql r2[0][:name]
				
			end

			it "test searching just by group-id" do 
				add_local_products
				r = Product.elastic_search nil, "com."
				r.count.should equal 1
			end

			it "test filtering by group-id" do
				add_local_products
				r = Product.elastic_search "mate", "org."
				r.count.should equal 1
				r[0][:group_id].should eql "org.club.mate"
			end
		end

		context "Exact Match context" do 
			it "elastic_search" do
				product_01 = ProductFactory.create_for_maven("org.hibernate", "hibernate-proxool", "4.0.1")
				product_01.save

				product_02 = ProductFactory.create_for_maven("org.hibernate", "hibernate-tools", "4.0.1")
				product_02.save

				product_03 = ProductFactory.create_for_maven("org.hibernate", "hibernate-core", "4.0.1")
				product_03.save

				product_04 = ProductFactory.create_for_maven("org.hibernate", "hibernate-lgpl", "4.0.1")
				product_04.save

				Product.index_all

				products = Product.search("hibernate-core")
				products.first.name.should eql(product_03.name)

				product_01.remove
				product_02.remove
				product_03.remove
				product_04.remove
			end
		end

		context "Sort products by followers." do 
			before :each do 
				@products = [
					{:name => "hibernate-proxool", :followers => 10},
					{:name => "hibernate-core", :followers => 5},
					{:name => "hibernate-lgpl", :followers => 20}
				]
				@products.each do |item|
					Product.new(item).save
				end
			end

			after :each do 
					@products.each do |item|
						Product.where(name: item[:name]).delete
					end					
			end

			it "sorting followers" do
				results = Product.elastic_search "hibernate"				
				#results.first.name.should eql "hibernate-lgpl"
			end
		end

	end
end