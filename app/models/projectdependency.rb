class Projectdependency

  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :project_id, type: String
  
  field :name, type: String
  field :group_id, type: String
  field :artifact_id, type: String
  
  field :version_current, type: String    # the newest version from the database
  field :version_requested, type: String  # locked version 
  field :version_label, type: String      # the version number from the Gemfile    
  field :comperator, type: String, :default => "="
  field :scope, type: String, :default => "compile"
  
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
    if !self.version_current.eql?(product.version)
      self.version_current = product.version
      self.save()
    end
    if self.version_requested.eql?(self.version_current)
      return false
    else 
      newest_version = Naturalsorter::Sorter.sort_version([self.version_current, self.version_requested]).last
      return false if newest_version.eql?(version_requested)
      return true
    end
  end
  
  def update_outdated
    self.outdated = is_outdated? 
  end

  def version_lbl
    # if version_label
    #   version_label
    # else
      version_requested
    # end
  end

  def comperator_lbl
    # if version_label && version_label.match(/.x$/)
      "="
    # else
    #   comperator
    # end
  end
  
end