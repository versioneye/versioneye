class LicenseMigration

  def self.migrate
    self.migrate_1
    self.migrate_2
  end

  def self.migrate_1
    products = Product.where(:license.ne => nil, :license.ne => '', :license.ne => 'unknown', :license.ne => 'UNKNOWN')
    self.process products
  end

  def self.migrate_2
    products = Product.where(:license_manual.ne => nil, :license_manual.ne => '', :license_manual.ne => 'unknown', :license_manual.ne => 'UNKNOWN')
    self.process products
  end

  def self.process( products )
    products.each do |product|
      next if product.license_info.nil? || product.license_info.empty?
      licenses = License.where(:language => product.language, :prod_key => product.prod_key)
      next if licenses && !licenses.empty?
      product.versions.each do |version|
        license = License.new({ :language => product.language, :prod_key => product.prod_key, :version => version.to_s,
          :name => product.license_info, :url => product.license_link_info })
        license.save
        p "create license #{license.name} - #{license.url} for #{license.prod_key} : #{license.version}"
      end
      # product.license = nil
      # product.licenseLink = nil
      # product.license_manual = nil
      # product.licenseLink_manual = nil
      # product.save
    end
  end

end
