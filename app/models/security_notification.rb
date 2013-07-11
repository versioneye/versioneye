class SecurityNotification
  include Mongoid::Document
  
  field :summary, type: String
  fields "language-issue", type: String
  
  scope ->(lang){where({"language-issue" => true})}
end
