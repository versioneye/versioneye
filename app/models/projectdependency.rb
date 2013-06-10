class Projectdependency

  # This Model describes the relationship between a project and a package
  # This Model describes 1 dependency of a project

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SECONDS_PER_DAY = 5184000

  field :prod_key   , type: String
  field :ext_link   , type: String # Link to external package. For example zip file on GitHub / Google Code.

  field :name       , type: String
  field :group_id   , type: String
  field :artifact_id, type: String

  field :version_current  , type: String  # the newest version from the database
  field :version_requested, type: String  # locked version
  field :version_label    , type: String  # the version number from the projectfile (Gemfile, package.json)
  field :comperator       , type: String, :default => "="
  field :scope            , type: String, :default => Dependency::A_SCOPE_COMPILE
  field :release          , type: Boolean
  field :stability        , type: String, :default => VersionTagRecognizer::A_STABILITY_STABLE

  field :outdated           , type: Boolean
  field :outdated_updated_at, type: DateTime, :default => Time.now

  belongs_to :project


  def product
    Product.find_by_key(self.prod_key)
  end

  def find_or_init_product
    product = Product.find_by_key(prod_key) if self.prod_key
    product = init_product if product.nil?
    product
  end

  def unknown?
    prod_key.nil? && ext_link.nil?
  end

  def outdated?
    return update_outdated! if self.outdated.nil?
    last_update_ago = Time.now - self.outdated_updated_at
    return self.outdated if last_update_ago < A_SECONDS_PER_DAY
    return update_outdated!
  end

  def update_outdated!
    update_version_current

    if ( self.prod_key.nil? && self.version_current.nil? ) ||
       ( self.version_requested.eql?("GIT") || self.version_requested.eql?("PATH") ) ||
       ( self.version_requested.eql?(self.version_current) )
      return update_outdated( false )
    end

    newest_version = Naturalsorter::Sorter.sort_version([self.version_current, self.version_requested]).last
    if newest_version.eql?(version_requested)
      return update_outdated( false )
    end

    update_outdated( true )
    self.outdated
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

  private

    def init_product
      product             = Product.new
      product.name        = self.name
      product.group_id    = self.group_id
      product.artifact_id = self.artifact_id
      product
    end

    def update_outdated( out_value )
      self.outdated = out_value
      self.outdated_updated_at = Time.now
      self.save
      self.outdated
    end

    # TODO refactor this. Move code!
    def update_version_current
      return false if self.prod_key.nil?
      product = Product.find_by_key self.prod_key
      return false if product.nil?
      version_service = VersionService.new product
      newest_version       = version_service.newest_version_number( self.stability )
      self.version_current = newest_version
      self.release         = VersionTagRecognizer.release? self.version_current
      self.save()
    end

end
