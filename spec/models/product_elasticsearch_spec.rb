require 'spec_helper'

def add_local_products
	@prods.each do |prod|
    	product = Product.new prod
    end
end

def get_index_count
	response = RestClient.get("http://localhost:9200/#{Product.index_name}/_count")
	JSON.parse(response)["count"]
end 

describe Product do

	before :each do
		@prods = [		
			{:name => "club-mate",        :language => "java", :group_id => "org.club.mate"},
			{:name => "club-mate-parent", :language => "java", :group_id => "com.club.mate"},
			{:name => "club-mate-child",  :language => "java", :group_id => "net.club.mate"},
			{:name => "club-mate-c",      :language => "c",    :group_id => ""},
			{:name => "club-mate-ccc",    :language => "c++",  :group_id => ""},
			{:name => "club-mate-ruby",   :language => "ruby", :group_id => ""},
			{:name => "club-mate-cnet",   :language => "c#",   :group_id => "net.microsoft.crap"},
			{:name => "bad.mate.jar", 	  :language => "mate", :group_id => "club.mate.org"},
			{:name => "good.mate.jar",    :language => "mate", :group_id => "club.mate.org"},
			{:name => "superb_mate.jar",  :language => "mate", :group_id => "club.mate.org"}
		]
		@products = Array.new
		@prods.each do |prod| 
			product = Product.new(prod)
			product.save
			@products.push product
		end
	end

	after :each do		
		Product.clean_all
		Product.where().delete
	end
	
	context "With no indexes: " do
		it "does clean_all successfull" do
			Product.clean_all.should be_true
		end
		it "throws exception because no index" do
			Product.elastic_search("random query").should raise_exception
		end
	end

	context "Only one product in Index." do
		it "adds one element to the index" do
			product = @products[0]
			response = product.index_one
			response.code.should eql(200)
		end 
		it "Finds the only element in the index by name" do
			Product.clean_all
			product = Product.new(:name => "rails")
			product.save
			sleep 2 # sleep for 2 seconds until the product gets indexed via REST. 
			results = Product.elastic_search "rails"
			results.count.should eql(1)
		end
	end

	context "Club-Mate in the house" do
		it "Finds club-mate first!" do
			sleep 5
			results = Product.elastic_search "club-mate"
			results.count.should eql(@prods.count)
			results.each do |result|
				p "#{result.name}"
			end
			results[0].name.should eql("club-mate")
		end
	end

	context "- index only documents, which has flagged to reindex" do
		it "index_newest" do
			Product.clean_all
            @products.each do |product|
            	product.update_attribute(:reindex, true)            
            end
            Product.index_newest
            get_index_count.should equal @products.count 

            Product.where(reindex: true).count.should equal 0               
		end
	end

	context " - index all documents in `products` collection" do 
		it "index_all" do
			Product.clean_all
			sleep 4
			add_local_products
			Product.index_all
			sleep 4
			get_index_count.should eql(Product.count) 
		end
	end

	context "- tests search functionalities " do
		it "search empty string should rais exception" do
			Product.index_all 
			expect { Product.elastic_search("") }.to raise_error(ArgumentError)
		end

		#TODO: c gaves every c language, but c++ and c# dont work at all
		it "test language filtering"  do 
			sleep 4
			Product.elastic_search("club-mate", nil, "java").count.should eql(3)
		end

		it "test, does language filtering is case insensitive" do
			sleep 4
			results1 = Product.elastic_search "club-mate", nil, "Java"
			results2 = Product.elastic_search "club-mate", nil, "java"
			results1[0][:name].should eql results2[0][:name]
			results1.count.should eql(results2.count)
		end

		it " - should return 1 result with the right group_id." do 
			sleep 5
			results = Product.elastic_search nil, "com."
			results.count.should eql(1)
			results[0].group_id.should eql("com.club.mate")
		end

		it "test filtering by group-id" do
			sleep 4
			results = Product.elastic_search "mate", "org."
			results.count.should eql(1)
			results[0][:group_id].should eql "org.club.mate"
		end

		it "test finding names, which includes points" do
			sleep 4
			results = Product.elastic_search "bad.mate.jar"
			results.count.should eql(1)			
		end 

		it "test finding names, which includes underscores" do 
			sleep 3
			results = Product.elastic_search "superb_mate.jar"			
			results.count.should eql(1)
		end
	end
	
end