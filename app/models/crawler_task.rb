class CrawlerTask
  include Mongoid::Document
  include Mongoid::Timestamps

  A_SOURCE_GITHUB   = "github"
  A_SOURCE_URL      = "url"

  field :runs,          type: Integer, default: 0 #how many times crawled
  field :fails,         type: Integer, default: 0 #how many times failed
  field :task_target,   type: String #use format <crawlers_name>/<task_name>
  field :task_source,   type: String 
  field :task_failed,   type: Boolean, default: false
  field :re_crawl,      type: Boolean, default: false 
  field :source,        type: String #github | plain url | ... 
  field :url,           type: String
  field :url_params,    type: Hash
  field :url_exists,    type: Boolean, default: false
  field :repo_owner,    type: String
  field :repo_name,     type: String
  field :repo_fullname, type: String
  field :repo_weight,   type: Integer, default: 0 #weight = stars + watchers 
  field :data,          type: Hash #subdocument to keep pre-cached data

  scope :by_task, ->(name){where(task_target: name)}
  scope :re_crawlable, where(re_crawl: true, task_failed: false, url_exists: true)

end
