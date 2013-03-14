class Projectdependency

  # Minimum stability for PHP composer
  # https://igor.io/2013/02/07/composer-stability-flags.html
  # 
  A_STABILITY_STABLE = "stable"
  A_STABILITY_RC = "RC"
  A_STABILITY_BETA = "beta"
  A_STABILITY_ALPHA = "alpha"
  A_STABILITY_DEV = "dev"
  A_STABILITY_PRE = "pre"

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
  field :release, type: Boolean
  field :stability, type: String, :default => A_STABILITY_STABLE
  
  field :prod_key, type: String
  field :prod_type, type: String
  field :outdated, type: Boolean
  field :ext_link, type: String    # Link to external package. For example zip file on GitHub / Google Code. 
  
  
  def find_or_init_product
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

  def unknown?
    prod_key.nil? && ext_link.nil? 
  end
  
  # TODO Write tests for the case that prod_key is nil and version_current is not nil 
  # 
  def outdated?
    if self.prod_key.nil? && self.version_current.nil? 
      self.outdated = false
      return false 
    end
    
    product = Product.find_by_key prod_key
    if product 
      newest_version = product.newest_version_number( self.stability )
      self.version_current = newest_version
      self.save() 
    end

    if self.version_requested.eql?("GIT")
      self.outdated = false
      return false
    end
    
    if self.version_requested.eql?(self.version_current)
      self.outdated = false
      return false
    end 
    
    newest_version = Naturalsorter::Sorter.sort_version([self.version_current, self.version_requested]).last
    if newest_version.eql?(version_requested)
      self.outdated = false
      return false   
    end
    
    self.outdated = true
    self.release = ReleaseRecognizer.release? self.version_current
    return true
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

  def link 
    if self.prod_key 
      key = Product.encode_product_key( prod_key )
      return "/package/#{key}"
    elsif self.ext_link 
      return self.ext_link
    else 
      return "#"
    end
  end
  
end