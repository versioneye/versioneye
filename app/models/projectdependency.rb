class Projectdependency

  # This Model describes the relationship between a project and a package
  # This Model describes 1 dependency of a project

  include Mongoid::Document
  include Mongoid::Timestamps

  A_SECONDS_PER_DAY = 24 * 60 * 60 # 24h * 60min * 60s = 86400

  # This project dependency refers to the product with the given language and prod_key
  field :language   , type: String
  field :prod_key   , type: String
  field :ext_link   , type: String # Link to external package. For example zip file on GitHub / Google Code.

  field :name       , type: String
  field :group_id   , type: String # Maven specific
  field :artifact_id, type: String # Maven specific

  field :version_current  , type: String  # the newest version from the database
  field :version_requested, type: String  # requested version from the project file -> locked version
  field :version_label    , type: String  # the version number from the projectfile (Gemfile, package.json)
  field :comperator       , type: String, :default => "="
  field :scope            , type: String, :default => Dependency::A_SCOPE_COMPILE
  field :release          , type: Boolean
  field :stability        , type: String, :default => VersionTagRecognizer::A_STABILITY_STABLE

  field :outdated           , type: Boolean
  field :outdated_updated_at, type: DateTime, :default => Time.now
  field :muted              , type: Boolean, default: false

  belongs_to :project

  def product
    Product.fetch_product( self.language, self.prod_key )
  end

  def find_or_init_product
    product = Product.fetch_product( language, prod_key) if self.prod_key
    if product.nil? && ( !group_id.to_s.empty? && !artifact_id.to_s.empty? )
      product = Product.find_by_group_and_artifact self.group_id, self.artifact_id
    end
    product = init_product if product.nil?
    product
  end

  def unknown?
    prod_key.nil? && ext_link.nil?
  end

  def known?
    !self.unknown?
  end

  def outdated?
    return update_outdated! if self.outdated.nil?
    last_update_ago = Time.now - self.outdated_updated_at
    return self.outdated if last_update_ago < A_SECONDS_PER_DAY
    update_outdated!
  end

  def release?
    if self.release.nil?
      self.release = VersionTagRecognizer.release? self.version_current
      self.save
    end
    self.release
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

  def to_s
    "<Projectdependency: #{project} depends on #{name} (#{version_label}) current: #{version_current} >"
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

    # TODO refactor this. Move code to service layer !
    #
    def update_version_current
      return false if self.prod_key.nil?
      product = Product.fetch_product self.language, self.prod_key
      return false if product.nil?
      newest_version       = VersionService.newest_version_number( product.versions, self.stability )
      return false if newest_version.nil? || newest_version.empty?
      if self.version_current.nil? || self.version_current.empty? || !self.version_current.eql?( newest_version )
        self.version_current = newest_version
        self.release         = VersionTagRecognizer.release? self.version_current
        self.muted = false
        self.save()
      end
    end

end
