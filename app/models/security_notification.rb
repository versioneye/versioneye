class SecurityNotification

  include Mongoid::Document
  include Mongoid::Timestamps

  field :cve_id       , type: String
  field :summary      , type: String
  field :published    , type: DateTime
  field :last_modified, type: DateTime

  field :score

  #embeds_many :softwares

  def self.parse_doc(doc)
    entry = doc.read
    if entry.root.name == "entry" and not entry.empty_element?
      entry_doc = Nokogiri::XML(entry.inner_xml)
      p entry_doc.xpath("//vulnerable-software-list")
    end
  end

  def self.make_doc_reader(filepath)
    # Open the file on disk and pass it to Nokogiri so that it can stream read;
    f = File.open('./public/cves/nvdcve-2.0-2013.xml','r')
    doc = Nokogiri::XML::Reader(f)
    return doc
  end


end
