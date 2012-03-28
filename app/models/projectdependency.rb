class Projectdependency

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :project_id, type: String
  
  field :name, type: String
  field :group_id, type: String
  field :artifact_id, type: String
  field :version, type: String
  field :prod_key, type: String
  field :prod_type, type: String
  field :outdated, type: Boolean
  
  def get_product
    if !self.prod_key.nil?
      product = Product.find_by_key(prod_key)
    end
    if product.nil?
      product = Product.new
      product.name = self.name
      product.group_id = self.group_id
      product.artifact_id = self.artifact_id
    end
    product
  end
  
  def is_outdated?
    return false if self.prod_key.nil?     
    product = get_product
    current_version = product.version
    return false if product.wouldbenewest?(version)
    return false if current_version.eql? version
    return true
  end
  
  def update_outdated
    if is_outdated? 
      self.outdated = true
    else 
      self.outdated = false
    end
  end
  
end