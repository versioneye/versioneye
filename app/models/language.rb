class Language
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  field :description, type: String
  field :supported_managers, type: String
  field :latest_version, type: String
  field :stable_version, type: String
  field :licence, type: String
  field :licence_url, type: String

  field :main_url, type: String
  field :wiki_url, type: String
  field :repo_url, type: String
  field :issue_url, type: String
  field :mailinglist_url, type: String
  field :irc_url, type: String
  field :irc, type: String
  field :twitter_name, type: String

  scope :by_language, ->(lang){where(name: Product.decode_language(lang))}

end
