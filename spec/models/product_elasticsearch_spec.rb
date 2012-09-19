require 'spec_helper'

def add_local_products
	@products.each do |item|
    	p = Product.new item
    	p.update_attribute(:reindex, true)            
    end
    Product.index_newest
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
			{:name => "club-mate-cnet",   :language => "c#",   :group_id => "net.microsoft.crap"}
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
			product = Product.new(:name => "rails")
			product.save
			product.index_one
			results = Product.elastic_search "rails"
			results.count.should eql 1
		end
	end

	# context "Club-Mate in the house" do
	# 	it "adds all to the index" do
	# 		response = Product.index_all
	# 		response.code.should eql(200)
	# 	end 
	# 	it "Finds the only element in the index by name" do
	# 		product = Product.new(:name => "rails")
	# 		product.save
	# 		product.index_one
	# 		results = Product.elastic_search "rails"
	# 		results.count.should equal 1
	# 	end
	# end

		# context "- index only documents, which has flagged to reindex" do
		# 	it "index_newest" do
		# 		#initialize data collection
		# 		Product.clean_all
  #               @products.each do |item|
  #               	p = Product.new item
  #               	p.update_attribute(:reindex, true)            
  #               end
  #               r = Product.index_newest
  #               get_index_count.should equal @products.count 

  #               #test, there's anymore document to reindex
  #               Product.where(reindex: true).count.should equal 0               
		# 	end

		# end

		# context "- index all documents in `products` collection" do 
		# 	it "index_all" do
		# 		Product.clean_all
		# 		add_local_products
		# 		r = Product.index_all
		# 		get_index_count.should equal Product.count
		# 	end
		# end

		# context "- tests search functionalities " do
		# 	it "search empty string" do
		# 		Product.index_all 
		# 		r = Product.elastic_search ""
		# 		r.count.should equal 0				
		# 	end

		# 	#TODO: c gaves every c language, but c++ and c# dont work at all
		# 	it "test language filtering"  do 
		# 		add_local_products
		# 		Product.elastic_search("club-mate", nil, "java").count.should equal 3
		# 		#Product.elastic_search("club-mate", "c,c++").count.should equal 2
		# 		Product.elastic_search("club-mate", nil, "c,c#,c++").count.should equal 3
		# 	end

		# 	it "test, does language filtering is case insensitive" do
		# 		add_local_products
		# 		r1 = Product.elastic_search "club-mate", nil, "Java"
		# 		r2 = Product.elastic_search "club-mate", nil, "java"
		# 		r1[0][:name].should eql r2[0][:name]
				
		# 	end

		# 	it "test searching just by group-id" do 
		# 		add_local_products
		# 		r = Product.elastic_search nil, "com."
		# 		r.count.should equal 1
		# 	end

		# 	it "test filtering by group-id" do
		# 		add_local_products
		# 		r = Product.elastic_search "mate", "org."
		# 		r.count.should equal 1
		# 		r[0][:group_id].should eql "org.club.mate"
		# 	end
		# end

		# context "Exact Match context" do 
		# 	before :each do 
		# 		@products = [
		# 			{:name => "hibernatecoreparent", :followers => 20, :description => "A module of the Hibernate Core project "},
		# 			{:name => "hibernatecore",        :followers => 20, :description => "A module of the Hibernate Core project "},
		# 			{:name => "hibernateehcache",     :followers => 20, :description => "A module of the Hibernate Core project "}, 
		# 			{:name => "hibernateproxool",     :followers => 20, :description => "A module of the Hibernate Core project "}, 
					
		# 		]
		# 		@products.each do |item|
		# 			Product.new(item).save
		# 		end
		# 	end

		# 	after :each do 
		# 		@products.each do |item|
		# 			prods = Product.where(name: item[:name])
		# 			prods.each do |product|
		# 				product.remove
		# 			end
		# 		end					
		# 	end

		# 	it "finds the exact match first" do
		# 		Product.index_all
		# 		products = Product.elastic_search("hibernatecore").results
		# 		p "count #{products.count} products"
		# 		prod_01 = products.first
		# 		prod_02 = products[1]
		# 		prod_01.name.should eql("hibernatecore")
		# 		prod_02.name.should eql("hibernatecoreparent")
		# 	end
		# end

		# context "Sort products by followers." do 
		# 	before :each do 
		# 		@products = [
		# 			{:name => "hibernate-proxool", :followers => 10},
		# 			{:name => "hibernate-core", :followers => 5},
		# 			{:name => "hibernate-lgpl", :followers => 20}
		# 		]
		# 		@products.each do |item|
		# 			Product.new(item).save
		# 		end
		# 	end

		# 	after :each do 
		# 		@products.each do |item|
		# 			prods = Product.where(name: item[:name])
		# 			prods.each do |product|
		# 				product.remove
		# 			end
		# 		end
		# 	end

		# 	it "sorting followers" do
		# 		results = Product.elastic_search "hibernate"				
		# 		#results.first.name.should eql "hibernate-lgpl"
		# 	end
		# end

	
end