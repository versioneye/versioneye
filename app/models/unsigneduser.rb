class Unsigneduser < ActiveRecord::Base
  
  validates :email,    :presence    => true,
                       :length      => {:minimum => 5, :maximum => 254},
                       :uniqueness  => true,
                       :format      => {:with => /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/}
                       
  def self.find_by_email(e_mail)    
    if /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/.match e_mail
      unsigned_user = Unsigneduser.where("email like ?", e_mail)
      return unsigned_user[0] unless unsigned_user.nil?
    end    
    return nil
  end
  
end