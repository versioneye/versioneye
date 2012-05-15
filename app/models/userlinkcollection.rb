class Userlinkcollection
  
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String 
  field :linkedin, type: String
  field :xing, type: String
  field :gulp, type: String
  field :github, type: String
  field :stackoverflow, type: String
  field :twitter, type: String
  field :facebook, type: String

  def self.find_all_by_user(user_id)
  	Userlinkcollection.first( conditions: { user_id: user_id })
  end

  def empty?
  	linkedin.nil? && xing.nil? && gulp.nil? && github.nil? && stackoverflow.nil? && twitter.nil? && facebook.nil? && linkedin.empty? && xing.empty? && gulp.empty? && github.empty? && stackoverflow.empty? && twitter.empty? && facebook.empty? 
  end

end