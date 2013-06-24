class Version

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  # self.collection_name = 'people'

  field :uid, type: String
  field :version, type: String
  field :link, type: String
  field :downloads, type: Integer
  field :authors, type: String
  field :description, type: String
  field :summary, type: String
  field :prerelease, type: Boolean
  field :mistake, type: Boolean
  field :pom, type: String
  field :released_at, type: DateTime
  field :released_string, type: String
  field :license, type: String

  embedded_in :product

  def as_json(parameter=nil)
    {
      :version => self.version,
      :uid => self.get_decimal_uid,
      :link => self.link,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end

  def self.encode_version(version)
    return nil if version.nil?
    version.gsub("/", ":")
  end

  def self.decode_version(version)
    return nil if version.nil?
    version.gsub(":", "/")
  end

  def to_param
    val = Version.encode_version(self.version)
    "#{val}".strip
  end

  def from_param
    Version.decode_version self.version
  end

  def to_url_param
    self.to_param
  end

  def get_decimal_uid
    uid.to_s.to_i(16).to_s(10)
  end

  def versionlink
    Versionlink.all(conditions: { prod_key: self.product.prod_key, version_id: self.version}).asc(:name)
  end

  def versionchange
    Versionchange.all(conditions: { prod_key: self.product.prod_key, version_id: self.version})
  end

  def versionarchive
    Versionarchive.all(conditions: { prod_key: self.product.prod_key, version_id: self.version}).asc(:name)
  end

end
