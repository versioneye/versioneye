class Versionlink

  include Mongoid::Document
  include Mongoid::Timestamps

  # If version_id is nil this link belongs to all versions of the software package.

  # Belongs to the product with this attributes
  field :language  , type: String
  field :prod_key  , type: String
  field :version, type: String 

  field :link      , type: String # URL:   for example https://github.com/500px/500px-iOS-api
  field :name      , type: String # Label: for example "500px-iOS-api"
  # true  => This link was manually added by a community member
  # false => This link was crawled
  field :manual    , type: Boolean, :default => false

  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime('%Y.%m.%d %I:%M %p'),
      :updated_at => self.updated_at.strftime('%Y.%m.%d %I:%M %p')
    }
  end

  def product
    product = nil
    if self.language
      product = Product.find_by_lang_key( self.language, self.prod_key )
    end
    return nil if product.nil?
    product.version = self.version
    product
  end

  def self.find_by( language, prod_key, link )
    return nil if link.nil? || link.strip.empty?
    Versionlink.where( language: language, prod_key: prod_key, link: link ).shift
  end

  def self.find_version_link(language, prod_key, version, link)
    Versionlink.where( language: language, prod_key: prod_key, version: version, link: link )
  end

  def self.create_versionlink language, prod_key, version_number, link, name
    return nil if link.to_s.empty?
    if link.match(/^http.*/).nil? && link.match(/^git.*/).nil?
      link = "http://#{link}"
    end
    versionlinks = Versionlink.find_version_link(language, prod_key, version_number, link)
    if versionlinks && !versionlinks.empty?
      Rails.logger.info "-- link exist already : #{prod_key} - #{version_number} - #{link} - #{name}"
      return nil
    end
    versionlink = Versionlink.new({:name => name, :link => link, :language => language,
      :prod_key => prod_key, :version => version_number })
    versionlink.save
  end

  def get_link
    return "http://#{self.link}" if self.link.match(/^www.*/) != nil
    self.link
  end

end
