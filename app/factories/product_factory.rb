class ProductFactory

    def self.create_new(n = 1, manager_type = :maven, save_db = true)
      name = "test_#{:class.to_s}_#{n}"
      version = "#{Random.rand(0..4)}.#{Random.rand(1..9)}"

      case manager_type.to_sym
      when :maven
        product = self.create_for_maven("versioneye", name, version)
      when :composer
        product = self.create_for_composer(name, version)
      when :gemfile
        product = self.create_for_gemfile(name, version)
      end

      product.save if save_db
      return product
    end

	def self.create_for_maven(group_id, artifact_id, version)
	  version_obj = Version.new :version => version
	
      product = Product.new({
        :name         => artifact_id,
        :name_downcase => artifact_id.downcase,
        :group_id     => group_id,
        :artifact_id  => artifact_id,
        :prod_key     => "#{group_id}/#{artifact_id}",
        :language     => "Java"
      })
	  product.versions.push(version_obj)
	  product.version = version
	  product
	end


	def self.create_for_composer(name, version)
		product = Product.new
		product.name = name
		product.name_downcase = name.downcase
		product.prod_key = "php/#{name}"
		product.language = "PHP"
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
		product.language = "Ruby"
		version_obj = Version.new
		version_obj.version = version
		product.versions.push(version_obj)
		product.version = version
		product
	end

end
