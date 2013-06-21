class SubmittedUrlFactory

  def self.create_new(extra_data = nil, save_db = true)
    random_id = Random.rand(1..100)
    new_url = "http://www.#{self.name}.com/#{random_id}"
    new_message = "dummy_data_#{random_id}"
    user_data = {:url => new_url, :message => new_message}

    user_data.merge!(extra_data) unless extra_data.nil? or extra_data.empty?
    new_item = SubmittedUrl.new user_data

    new_item.save if save_db
    return new_item
  end

end
