class PromoCode

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name                 , type: String
  field :end_date             , type: DateTime, default: (DateTime.now + 30.days)
  field :free_private_projects, type: Integer, default: 2
  field :redeemed             , type: Integer, default: 0

  validates_uniqueness_of :name, :message => 'Name exist already.'

  def to_s
    "#{name} - free private projects: #{free_private_projects}. Ends: #{end_date}"
  end

  def self.by_name name
    PromoCode.where(:name => name).shift
  end

  def is_valid?
    DateTime.now < end_date
  end

  def redeem!
    self.redeemed = self.redeemed.to_i + 1
    self.save
  end

end
