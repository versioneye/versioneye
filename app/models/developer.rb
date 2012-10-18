class Developer

  include Mongoid::Document
  include Mongoid::Timestamps

  field :prod_key, type: String  
  field :version, type: String 
  field :developer, type: String   
  field :name, type: String 
  field :email, type: String 
  field :homepage, type: String 
  field :organization, type: String 
  field :organization_url, type: String 
  field :role, type: String 
  field :timezone, type: String

  def self.find_by prod_key, version, name 
    Developer.where(prod_key: prod_key, version: version, name: name)
  end

end