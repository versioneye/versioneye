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
  
  def self.find_by_id(id)
    comment = Versioncomment.find(:first, :conditions => ["id = ?", id])
    comment
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
  
  def self.get_flatted_average(avg)
    avg = 10 if avg < 15 && avg > 0
    avg = 20 if avg < 25 && avg >= 15
    avg = 30 if avg < 35 && avg >= 25
    avg = 40 if avg < 45 && avg >= 35
    avg = 50 if avg >= 45
    p "get_flatted_average #{avg}"
    avg
  end

end