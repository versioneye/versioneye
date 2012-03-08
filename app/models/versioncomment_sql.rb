class VersioncommentSql < ActiveRecord::Base
  
  set_table_name "versioncomments"
  
  belongs_to :user,           :class_name => "UserSql"
    
  validates :comment,  :presence      => true,
                       :length        => { :within => 2..1000 }  
  validates :rate,     :presence      => true
  validates :version,  :presence      => true  
  
  
  def as_json parameter
    product = get_product
    prod_name = product.name unless product.nil?
    prod_key = product.prod_key unless product.nil?
    {
      :rate => self.rate,
      :comment => self.comment,
      :from => user.fullname,
      :product_name => prod_name,
      :product_key => prod_key,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end
  
  def self.find_by_id(id)
    Versioncomment.find(:first, :conditions => ["id = ?", id])
  end
  
  def self.find_by_user_id(user_id)
    Versioncomment.where("user_id = ? ", user_id).order("created_at desc")
  end
  
  def self.find_by_prod_key_and_version(prod_key, version)
    Versioncomment.where("product_key = ? AND version = ?", prod_key, version).order("created_at asc")
  end
  
  def self.get_sum_by_prod_key_and_version(prod_key, version)
    Versioncomment.where("product_key = ? AND version = ?", prod_key, version).sum("rate")
  end
  
  def self.get_count_by_prod_key_and_version(prod_key, version)
    Versioncomment.where("product_key = ? AND version = ?", prod_key, version).count()
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
  
  def prod_key_url
    Product.to_url_param(self.product_key)
  end
  
  def version_url
    Product.to_url_param(self.version)
  end
  
  def name_and_version
    "#{self.prod_name} (#{self.version})" 
  end
  
  def self.update_product_names
    comments = VersioncommentSql.all
    comments.each do |comment|
      product = comment.get_product
      if !product.nil?
        comment.prod_name = product.name
        comment.save
      end      
    end
  end
  
  def self.migrate_to_mongo
    comments = VersioncommentSql.all
    comments.each do |comment|
      p "comment: #{comment.id}"
      vc = Versioncomment.new
      vc.user_id = comment.user_id
      vc.product_key = comment.product_key
      vc.prod_name = comment.prod_name
      vc.version = comment.version
      vc.rate = comment.rate
      vc.comment = comment.comment
      vc.save
    end
  end
  
  def get_product
    product = Product.find_by_key(self.product_key)
    if !product.nil?
      product.version = self.version
    end
    product
  end
  
  def self.get_flatted_average(avg)
    avg = 10 if avg < 15 && avg > 0
    avg = 20 if avg < 25 && avg >= 15
    avg = 30 if avg < 35 && avg >= 25
    avg = 40 if avg < 45 && avg >= 35
    avg = 50 if avg >= 45
    avg
  end

end