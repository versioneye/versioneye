class LanguageFeed
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title,     type: String
  field :url,       type: String
  field :language,  type: String

  scope :by_language, ->(lang){where(language: lang)}

end
