require 'grape'

require_relative 'helpers/session_helpers_v1.rb'
require_relative 'helpers/paging_helpers_v1.rb'
require_relative 'helpers/user_helpers_v1.rb'


class UsersApiV1 < Grape::API

  helpers SessionHelpersV1
  helpers PagingHelpersV1
  helpers UserHelpersV1

  resource :me do
    desc "shows profile of authorized user", {
      notes: %q[
          On Swagger, you can create session by adding additional parameter :api_key
      ]
    }
    get do
      authorized?
      @current_user[:notifications] = {
        :new => Notification.by_user_id(@current_user.id).all_not_sent.count,
        :total => Notification.by_user_id(@current_user.id).count
      }
      present @current_user, with: EntitiesV1::UserDetailedEntity
    end

    desc "shows favorite packages for authorized user"
    params do
      optional :page, type: Integer, desc: "page number for pagination"
    end
    get '/favorites' do
      authorized?
      make_favorite_response(@current_user, params[:page], 30)
    end

    desc "show comments of authorized user"
    params do
      optional :page, type: Integer, desc: "page number for pagination"
    end
    get '/comments' do
      authorized?
      make_comment_response(@current_user, params[:page], 30)
    end

    desc "show unread notifications of authorized user", {
      notes: "It will show version updates that's not yet sent by email."
    }
    get '/notifications' do
      authorized?

      unread_notifications = Notification.by_user(@current_user).desc(:created_at).limit(30)
      temp_notice = Notification.new #grape cant handle plain Hashs w.o to_json
      temp_notice[:user_info] = @current_user
      temp_notice[:unread] = unread_notifications.count
      temp_notice[:notifications] = unread_notifications
    
      present temp_notice, with: EntitiesV1::UserNotificationEntity
    end
  end

  resource :users do
    before do
      track_apikey
    end

    desc "shows profile of given user_id"
    params do
      requires :username, :type => String, :desc => "username"
    end
    get '/:username' do
        authorized?
        @user = User.find_by_username(params[:username])
        present @user, with: EntitiesV1::UserEntity
    end

    desc "show users' favorite packages"
    params do
      requires :username, :type => String, :desc => "username"
      optional :page, :type => Integer, :desc => "Pagination number"
    end
    get '/:username/favorites' do
       authorized?
       @user = User.find_by_username(params[:username])
       error!("User with username `#{params[:username]}` dont exists.", 400) if @user.nil?

       make_favorite_response(@user, params[:page], 30)
    end

    desc "show users' comments"
    params do
      requires :username, type: String, desc: "VersionEye users' nickname"
      optional :page, type: Integer, desc: "pagination number"
    end
    get '/:username/comments' do
      authorized?

      @user = User.find_by_username params[:username]
      error!("User #{params[:username]} dont exists", 400) if @user.nil?

      make_comment_response(@user, params[:page], 30)
    end
  end
end
