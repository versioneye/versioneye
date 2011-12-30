class Productrepo < ActiveRecord::Base

  belongs_to :product
  belongs_to :repository
  
end