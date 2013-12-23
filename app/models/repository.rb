class Repository

  include Mongoid::Document
  include Mongoid::Timestamps

  field :src     , type: String
  field :repotype, type: String

  embedded_in :product

  def as_json
    {
      :repo_source => self.src,
      :repo_type => self.repotype
    }
  end

  def to_s
    src
  end

end
