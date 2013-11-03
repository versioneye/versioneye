class Versionarchive

  include Mongoid::Document
  include Mongoid::Timestamps

  field :language  , type: String
  field :prod_key  , type: String
  field :version_id, type: String
  field :link      , type: String
  field :name      , type: String

  def as_json parameter
    {
      :name => self.name,
      :link => self.link,
      :created_at => self.created_at.strftime("%Y.%m.%d %I:%M %p"),
      :updated_at => self.updated_at.strftime("%Y.%m.%d %I:%M %p")
    }
  end

  def self.archives(lang, prod_key, version)
    Versionarchive.where(language: lang, prod_key: prod_key, version_id: version).asc(:name)
  end

  def self.create_archive_if_not_exist archive
    return nil if archive.link.nil? || archive.link.empty?
    if archive.link.match(/^http.*/).nil?
      archive.link = "http://#{archive.link}"
    end
    archives = Versionarchive.where(:language => archive.language, :prod_key => archive.prod_key,
      :version_id => archive.version_id, :link => archive.link )
    return nil if archives && !archives.empty?
    archive.save
  end

end
