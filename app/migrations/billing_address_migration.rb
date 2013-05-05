class BillingAddressMigration

  def self.migrate_billing_addresses
    addresses = BillingAddress.all
    addresses.each do |address|
      user = User.find(address.user_id)
      address.user = user 
      address.save 
    end
  end

end
