class CleanUp

  def self.start language
    affected = []
    products = Product.where(:language => "Python")
    products.each do |product|
      name = product.name
      gem_ = Product.where(:language => language, :name => name).first
      next if gem_.nil?

      versions = versions_for language, name
      next if versions.nil?

      gem_.versions.each do |ver|
        next if versions.include?(ver.to_s)

        p "Remove #{gem_.prod_key} : #{ver.to_s}"
        gem_.remove_version ver.to_s

        next if affected.include?(gem_.prod_key)

        affected << gem_.prod_key
      end
    end
    p "affected: #{affected.count}"
    affected
  end

  def self.versions_for language, name
    return versions_from_ruby_api(name) if language.eql?("Ruby")
    return versions_from_npm_api(name)  if language.eql?("Node.JS")
  end

  def self.versions_from_ruby_api name
    response = HttpService.fetch_response "http://rubygems.org/api/v1/versions/#{name}.json"
    return nil if response.nil? || response.body.nil? || response.body.empty? || response.body.eql?("This rubygem could not be found.")

    versions = JSON.parse response.body
    versions.collect{|ver| ver["number"]}
  end

  def self.versions_from_npm_api name
    response = HttpService.fetch_response "http://registry.npmjs.org/#{name}"
    return nil if response.nil? || response.body.nil? || response.body.empty?

    prod_json = JSON.parse response.body
    prod_json["versions"].collect{|prod| prod.first}
  rescue => e
    p e.message
    return nil
  end

end
