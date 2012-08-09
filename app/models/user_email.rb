class UserEmail

	include Mongoid::Document
	include Mongoid::Timestamps

	field :user_id, type: String
	field :email, type: String
	field :verification, type: String 

	def verified?
		self.verification.nil?
	end

	def create_verification
		random = create_random_value
		self.verification = secure_hash("#{random}--#{email}")
	end

	def self.find_by_email(email)
		UserEmail.first(conditions: {email: /^#{email}$/i})
	end

	def self.activate!(verification)
		user_email = UserEmail.first(conditions: {verification: verification})
		if user_email 
			user_email.verification = nil
			user_email.save
			return true
	    end
	    return false
	end

	private 

		def create_random_value
			chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
			value = ""
			10.times { value << chars[rand(chars.size)] }
			value
		end

		def secure_hash(string)
			Digest::SHA2.hexdigest(string)
		end

end