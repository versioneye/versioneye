class ComposerParser
  
  # Parser for composer.json files from composer, packagist.org. PHP
  def self.create_from_composer_url ( url )
    return nil if url.nil?
    resp = Net::HTTP.get_response(URI.parse(url))
    data = JSON.parse( resp.body )
    dependencies = data['require']
    return nil if dependencies.nil?

    project = Project.new
    project.dependencies = Array.new    

    dependencies.each do |key, value|
      dependency = Projectdependency.new
      dependency.name = key
      
      product = Product.find_by_key("php/#{key}")
      if product
        dependency.prod_key = product.prod_key
      end
      
      # TODO parse versin values from file ! 
      
      dependency.update_outdated
      if dependency.outdated?
        project.out_number = project.out_number + 1
      end      
      project.dependencies << dependency
    end

    project.dep_number = project.dependencies.count
    project
  end

end