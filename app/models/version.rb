class Version

  include Mongoid::Document
  include Mongoid::Timestamps

  field :uid, type: String
  field :version, type: String
  field :link, type: String
  field :rate, type: Integer
  field :ratecount, type: Integer
  field :downloads, type: Integer
  field :authors, type: String
  field :description, type: String
  field :summary, type: String
  field :prerelease, type: Boolean

  embedded_in :product
  
  def as_json parameter
    {
      :version => self.version,
      :uid => self.get_decimal_uid,
      :link => self.link,
      :rate => self.rate,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end  
  
  def update_rate
    prod_key = product.prod_key
    avg = Versioncomment.get_average_rate_by_prod_key_and_version(prod_key, version)
    avg_flat = Versioncomment.get_flatted_average(avg)
    self.rate = avg_flat
    self.ratecount = Versioncomment.get_count_by_prod_key_and_version(product.prod_key, version)    
  end
  
  def to_url_param
    url_param = String.new(version)
    url_param.gsub!("/","--")
    url_param.gsub!(".","~")
    "#{url_param}"    
  end
  
  def get_ratecount
    if self.ratecount.nil?
      self.ratecount = 0
    end
    self.ratecount
  end
  
  def get_decimal_uid
    uid.to_s.to_i(16).to_s(10)
  end
  
  def versionlink
    Versionlink.all(conditions: { prod_key: self.product.prod_key, version_id: self.version}).asc(:name)
  end
  
  def versionchange
    Versionchange.all(conditions: { prod_key: self.product.prod_key, version_id: self.version})
  end
  
  def versionarchive
    Versionarchive.all(conditions: { prod_key: self.product.prod_key, version_id: self.version}).asc(:name)
  end

end