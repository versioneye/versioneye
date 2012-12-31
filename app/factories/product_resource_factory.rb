class ProductResourceFactory

  def self.create_new(extra_data = nil, save_db = true)
    test_url = "http://www.versioneye.com/test/#{Random.rand(1..10000)}"
    resource_type = ["maven", "github"].sample(1).first

    resource_data = {
      :url => test_url,
      :resource_type => resource_type
    }

    resource_data.merge!(extra_data) unless extra_data.nil?
    new_resource = ProductResource.new(resource_data)
  
    new_resource.save if save_db
    return new_resource
  end
end
