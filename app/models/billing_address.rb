class BillingAddress

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :company, type: String
  field :street, type: String
  field :zip, type: String
  field :city, type: String
  field :country, type: String
  
  belongs_to :user 

  def update_from_params( params )
    self.name    = params[:name]
    self.company = params[:company]
    self.street  = params[:street]
    self.zip     = params[:zip_code]
    self.city    = params[:city]
    self.country = params[:country]
    self.save
  end

end
