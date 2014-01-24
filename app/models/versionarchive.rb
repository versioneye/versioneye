class Versionarchive

  # A Versionarchive describes a downloadable archive.
  # E.g. a link to a jar, zip or tar.gz file.

  include Mongoid::Document
  include Mongoid::Timestamps

  # Belongs to the product with this attributes
  field :language  , type: String
  field :prod_key  , type: String
  field :version_id, type: String # TODO rename to :version

  field :link      , type: String # URL
  field :name      , type: String # Label for the link/URL

  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime('%Y.%m.%d %I:%M %p'),
      :updated_at => self.updated_at.strftime('%Y.%m.%d %I:%M %p')
    }
  end

  def self.remove_archives language, prod_key, version_number
    Versionarchive.where( language: language, prod_key: prod_key, version_id: version_number ).delete_all
  end

  def self.archives(lang, prod_key, version)
    Versionarchive.where(language: lang, prod_key: prod_key, version_id: version).asc(:name).to_a
  end

  def self.create_archive_if_not_exist archive
    return nil if archive.link.nil? || archive.link.empty?
    archive.link = add_http( archive.link )
    return nil if exist_with_link?(archive.language, archive.prod_key, archive.version_id, archive.link)
    archive.save
  end

  def self.create_if_not_exist_by_name archive
    return nil if archive.link.nil? || archive.link.empty?
    archive.link = add_http( archive.link )
    return nil if exist_with_name?(archive.language, archive.prod_key, archive.version_id, archive.name)
    archive.save
  end

  def self.exist_with_name?(lang, prod_key, version, name)
    archive = Versionarchive.where(:language => lang, :prod_key => prod_key,
      :version_id => version, :name => name )
    !archive.nil? && !archive.empty?
  end

  def self.exist_with_link?(lang, prod_key, version, link)
    archive = Versionarchive.where(:language => lang, :prod_key => prod_key,
      :version_id => version, :link => link )
    !archive.nil? && !archive.empty?
  end

  def self.add_http( link )
    if link.match(/^http.*/).nil?
      link = "http://#{link}"
    end
    link
  end

end
