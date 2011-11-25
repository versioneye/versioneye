class Product < ActiveRecord::Base

  def self.find_by_name(searched_name)
    if searched_name.nil? || searched_name.strip == ""
      return nil
    end
    searched_name = "%"+searched_name+"%"
    Product.where("name ilike ?", searched_name).order("name asc")
  end

end