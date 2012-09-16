class ProductFactory

	def self.create_for_maven(group_id, artifact_id, version)
		product = Product.new
		product.name = artifact_id
		product.name_downcase = artifact_id.downcase
		product.group_id = group_id
		product.artifact_id = artifact_id
		product.prod_key = "#{group_id}/#{artifact_id}"
		version_obj = Version.new
		version_obj.version = version
		product.versions.push(version_obj)
		product.version = version
		product
	end

	def self.create_for_composer(name, version)
		product = Product.new
		product.name = name
		product.name_downcase = name.downcase
		product.prod_key = "php/#{name}"
		version_obj = Version.new
		version_obj.version = version
		product.versions.push(version_obj)
		product.version = version
		product
	end

	def self.create_for_gemfile(name, version)
		product = Product.new
		product.name = name
		product.name_downcase = name.downcase
		product.prod_key = name
		version_obj = Version.new
		version_obj.version = version
		product.versions.push(version_obj)
		product.version = version
		product
	end

end