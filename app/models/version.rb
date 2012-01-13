class Version
  include Mongoid::Document
  include Mongoid::Timestamps
  field :_id, type: String
  field :version, type: String
  field :link, type: String
  field :rate, type: Integer
  
  embedded_in :product
  
  def as_json parameter
    {
      :version => self.version,
      :link => self.link,
      :rate => self.rate,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end  
  
  def update_rate
    prod_key = product.prod_key
    self.rate = Versioncomment.get_average_rate_by_prod_key_and_version(prod_key, version)
  end
  
  def to_url_param
    url_param = String.new(version)
    url_param.gsub!("/","--")
    url_param.gsub!(".","~")
    "#{url_param}"    
  end

end