class Versioncomment

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  
  field :product_key, type: String
  field :prod_name, type: String
  field :language, type: String
  field :version, type: String
  
  field :comment, type: String
  field :update_type, type: String
  
  embeds_many :versioncommentreplys
  
  validates_presence_of :user_id,     :message => "User is mandatory!"
  validates_presence_of :product_key, :message => "Product is mandatory!"
  validates_presence_of :version,     :message => "Version is mandatory!"
  validates_presence_of :comment,     :message => "Comment is mandatory!"  
  
  def as_json parameter
    product = get_product
    prod_name = product.name unless product.nil?
    prod_key = product.prod_key unless product.nil?
    {
      :comment => self.comment,
      :from => user.fullname,
      :product_name => prod_name,
      :product_key => prod_key,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end
  
  def self.find_by_id(id)
    Versioncomment.first(conditions: { id: id} )
  end
  
  def self.find_by_user_id(user_id)
    Versioncomment.where(user_id: user_id).desc(:created_at)
  end

  def self.get_prod_keys_for_user(user_id)
    Versioncomment.where(user_id: user_id).distinct(:product_key)
  end

  def self.count_by_user_id(user_id)
    Versioncomment.where(user_id: user_id).count()
  end

  def self.find_by_prod_keys(prod_keys)
    Versioncomment.all( conditions: {:product_key.in => prod_keys}).desc(:created_at)
  end
  
  def self.find_by_prod_key_and_version(prod_key, version)
    Versioncomment.all( conditions: {product_key: prod_key, version: version} ).asc(:created_at)
  end
  
  def user
    User.find( self.user_id )
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
    comments = Versioncomment.all
    comments.each do |comment|
      product = comment.get_product
      if !product.nil?
        comment.prod_name = product.name
        comment.language = product.language
        comment.save
      end      
    end
  end
  
  def get_product
    product = Product.find_by_key(self.product_key)
    if !product.nil?
      product.version = self.version
    end
    product
  end

end