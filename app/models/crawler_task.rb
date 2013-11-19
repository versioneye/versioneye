class CrawlerTask
  include Mongoid::Document
  include Mongoid::Timestamps

  A_SOURCE_GITHUB   = "github"
  A_SOURCE_URL      = "url"

  field :runs,          type: Integer, default: 0 #how many times crawled
  field :fails,         type: Integer, default: 0 #how many times failed
  field :task_name,     type: String #use format <crawlers_name>/<task_name>
  field :task_done,     type: Boolean, default: false 
  field :recrawl,       type: Boolean, default: false 
  field :source,        type: String #github | plain url | ... 
  field :url,           type: String
  field :url_params,    type: Hash
  field :repo_owner,    type: String
  field :repo_name,     type: String
  field :repo_fullname, type: String
  field :repo_weight,   type: String #weight = stars + watchers 
  field :exists,        type: Boolean, default: false
  field :data,          type: Hash #subdocument to keep pre-cached data

  scope :by_task, ->(name){where(task_name: name)}
end
