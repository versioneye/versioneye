class Product < ActiveRecord::Base

  def self.find_by_name(searched_name)
    if searched_name.nil? || searched_name.strip == ""
      return nil
    end
    searched_name = "%"+searched_name+"%"
    Product.where("name ilike ?", searched_name).order("name asc")
  end
  
  def self.find_by_key(searched_key)
    if searched_key.nil? || searched_key.strip == ""
      return nil
    end
    products = Product.where("key ilike ?", searched_key)
    return products[0] unless products.nil?
    return nil
  end
  
  def to_param
    url_key = String.new(key)
    url_key.gsub!("/","--")
    url_key.gsub!(".","~")
    "#{url_key}"
  end
  
  def name_and_version    
    nameversion = "#{name} - (#{version})"
  end

end