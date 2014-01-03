require 'spec_helper'

describe NotificationMailer do

  describe 'new_version_email' do

    it 'should have the title of the post' do

      user = UserFactory.create_new
      notification = NotificationFactory.create_new user
      notifications = Notification.unsent_user_notifications user

      product = notification.product

      project = ProjectFactory.create_new user
      project_dep = Projectdependency.new({:language => product.language, :prod_key => product.prod_key, :project_id => project.id })
      project_dep.save

      email = NotificationMailer.new_version_email(user, notifications)

      email.encoded.should include( "Hello #{user.fullname}" )
      email.encoded.should include( 'There are new releases out there' )
      email.encoded.should include( '?utm_medium=email' )
      email.encoded.should include( 'utm_source=new_versoin' )
      email.encoded.should include( product.name )
      email.encoded.should include( notification.version_id )
      email.encoded.should include( "/user/projects/#{project._id.to_s}" )

      email.deliver!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
