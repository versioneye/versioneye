class JsonCache

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :json_string, type: String

  A_LANGUAGE_PROJECT_COUNT = 'lang_project_count'
  A_LANGUAGE_PROJECT_TREND = 'lang_project_trend'

  def self.language_project_count 
    JsonCache.where(:name => A_LANGUAGE_PROJECT_COUNT).first
  end

  def self.language_project_trend
    JsonCache.where(:name => A_LANGUAGE_PROJECT_TREND).first
  end

end
