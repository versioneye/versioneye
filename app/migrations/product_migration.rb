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

	def self.parse_release_date_global(lang)
		Product.where(language: lang).each do |product|
			product.versions.each do |version|
				if version.released_string.nil? 
					p "empty!"
					next 
				end
				version.released_at = DateTime.parse version.released_string
				version.save
				p "#{version.released_at}"
			end
			product.save
		end
	end

	def self.delete_double_deps(lang)
		Product.where(language: lang).each do |product|
			product.versions.each do |version|
				product.version = version.version 


				names = Hash.new 
				deps = product.dependencies("require")
				deps.each do |dep|
					if names[dep.name]
						p "remove #{product.prod_key} - #{product.version} - #{dep.name}"
						dep.remove
					else 
						names[dep.name] = dep
					end
				end
				
				names = Hash.new 
				deps = product.dependencies("require-dev")
				deps.each do |dep|
					if names[dep.name]
						p "remove #{product.prod_key} - #{product.version} - #{dep.name}"
						dep.remove
					else 
						names[dep.name] = dep
					end
				end
				
				names = Hash.new 
				deps = product.dependencies("replace")
				deps.each do |dep|
					if names[dep.name]
						p "remove #{product.prod_key} - #{product.version} - #{dep.name}"
						dep.remove
					else 
						names[dep.name] = dep
					end
				end

				
			end
		end
	end



	def self.check_emtpy_release_dates(lang)
		Product.where(language: lang).each do |product|
			product.versions.each do |version|
				if version.released_string.nil? 
					p "#{product.name} - #{version.version} - empty!"
					next 
				end
			end
		end
	end

end