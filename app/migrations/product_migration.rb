class ProductMigration

	def self.correct_namespace
		products = Product.where(:prod_type => "Packagist" )
		products.each do |product|

			product.name = product.prod_key.gsub("php/", "")
			product.save

			deps = Dependency.all(conditions: { prod_key: product.prod_key } )
			deps.each do |dep|
				dep.name = dep.dep_prod_key.gsub("php/", "")
				dep.save
			end

		end
	end

	def self.update_name_downcase_global
		products = Product.where(name_downcase: nil)
		products.each do |product|
			product.name_downcase = String.new(product.name.downcase)
			product.save
		end
	end

	def self.update_version_data_global
		count = Product.count()
		pack = 100
		max = count / pack 
		(0..max).each do |i|
			skip = i * pack
			products = Product.all().skip(skip).limit(pack)
			products.each do |product|
				product.update_version_data
			end
		end
	end

end