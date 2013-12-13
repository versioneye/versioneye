class Repository

  include Mongoid::Document
  include Mongoid::Timestamps

  field :repo_source, type: String
  field :repo_type  , type: String

  embedded_in :product

  def as_json
    {
      :repo_source => self.repo_source,
      :repo_type => self.repo_type
    }
  end

end
