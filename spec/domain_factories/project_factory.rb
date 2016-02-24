class ProjectFactory

  def self.create_new(user, extra_fields = nil, save = true)
    if user.nil? or user.to_s.empty?
      Rails.logger.error "User was unspecified or empty."
    end

    if user.is_a? Mongoid::Document
      user_id = user.id.to_s
    else
      user_id = user.to_s
    end

    project_data =  {
                      :user_id  =>  user_id,
                      :name     => "test_project"
                    }

    unless extra_fields.nil?
      project_data.merge!(extra_fields)
    end

    new_project = Project.new project_data
    if save
      unless new_project.save
        p new_project.errors.full_messages.to_sentence
      end
    end

    new_project
  end

end
