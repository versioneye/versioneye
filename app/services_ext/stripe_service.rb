class StripeService

  def self.fetch_customer customer_id
    Stripe::Customer.retrieve( customer_id )
  end

  
  def self.create_customer stripe_token, plan_name_id, email 
    Stripe::Customer.create(
        :card => stripe_token,
        :plan => plan_name_id,
        :email => email
      )
  end

  
  def self.create_or_update_customer user, stipe_token, plan_name_id
    customer = nil
    if user.stripe_customer_id 
      customer = self.fetch_customer user.stripe_customer_id
      customer.card = stripe_token
      customer.save
      customer.update_subscription( :plan => plan_name_id )
    else 
      customer = self.create_customer stripe_token, plan_name_id, user.email
    end
    customer
  end

end
