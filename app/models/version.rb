class Version

  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::MultiParameterAttributes

  field :uid            , type: String
  field :version        , type: String
  field :downloads      , type: Integer
  field :pom            , type: String
  field :released_at    , type: DateTime
  field :released_string, type: String

  embedded_in :product

  def to_s
    version.to_s
  end

  def as_json(parameter=nil)
    {
      :version    => self.version,
      :uid        => self.get_decimal_uid,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end

  def self.encode_version(version)
    return nil if version.nil?
    version.gsub("/", ":")
  end

  def released_or_detected
    return released_at if released_at
    created_at
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

end
