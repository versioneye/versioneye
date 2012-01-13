class Versioncomment < ActiveRecord::Base
  
  belongs_to :user,           :class_name => "User"
    
  validates :comment,  :presence      => true,
                       :length        => { :within => 2..1000 }
  
  def as_json parameter
    {
      :rate => self.rate,
      :comment => self.comment,
      :from => user.fullname,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end
  
  def self.find_by_prod_key_and_version(prod_key, version)
    comments = Versioncomment.where("product_key = ? AND version = ?", prod_key, version).order("created_at desc")
    comments
  end
  
  def self.get_sum_by_prod_key_and_version(prod_key, version)
    sum = Versioncomment.where("product_key = ? AND version = ?", prod_key, version).sum("rate")
    sum
  end
  
  def self.get_count_by_prod_key_and_version(prod_key, version)
    count = Versioncomment.where("product_key = ? AND version = ?", prod_key, version).count()
    count
  end
  
  def self.get_average_rate_by_prod_key_and_version(prod_key, version)
    avg = 0
    sum = Versioncomment.get_sum_by_prod_key_and_version(prod_key, version)
    count = Versioncomment.get_count_by_prod_key_and_version(prod_key, version)
    if count > 0
      avg = sum / count
    end
    avg
  end

end