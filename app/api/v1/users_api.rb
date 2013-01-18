require 'grape'
require_relative 'entities/user_entity.rb'
require_relative 'entities/product_entity.rb'
require_relative 'entities/version_comment_entity.rb'
require_relative 'entities/user_notification_entity.rb'
require_relative 'helpers/session_helpers.rb'

module VersionEye
  class UsersApi < Grape::API

    helpers SessionHelpers

    resource :me do
      desc "shows profile of authorized user"
      get do
        authorized?
        @current_user[:notifications] = {
          :new => Notification.by_user_id(@current_user.id).all_not_sent.count,
          :total => Notification.by_user_id(@current_user.id).count
        }
        present @current_user, with: Entities::UserDetailedEntity
      end

      desc "shows favorite packages for authorized user"
      get '/favorites' do
        authorized?
        user_favorites = @current_user.fetch_my_products
        present user_favorites, with: Entities::ProductEntity
      end

      desc "show comments of authorized user"
      get '/comments' do
        authorized?
        @comments  = Versioncomment.find_by_user_id @current_user.id
        @comments.each_with_index do |cmd, index|
          @comments[index][:product] = Product.find_by_key cmd.product_Key
        end
        present @comments, with: Entities::VersionCommentEntity
      end

      desc "show unread notifications of authorized user"
      get '/notifications' do
        authorized?

        unread_notifications = Notification.by_user_id(@current_user.id).all_not_sent
        temp_notice = Notification.new #grape cant handle plain Hashs w.o to_json
        temp_notice[:user_info] = @current_user
        temp_notice[:unread] = unread_notifications.count
        temp_notice[:notifications] = unread_notifications
      
        present temp_notice, with: Entities::UserNotificationEntity
      end
    end

    resource :users do
      desc "shows profile of given user_id"
      params do
        requires :username, :type => String, :desc => "username" 
      end
      get '/:username' do
          authorized?
          @user = User.find_by_username(params[:username])
          present @user, with: Entities::UserEntity
      end

      desc "show users' favorite packages"
      params do
        requires :username, :type => String, :desc => "username"
      end
      get '/:username/favorites' do
         authorized?
         @user = User.find_by_username(params[:username])
         present @user.fetch_my_products, with: Entities::ProductEntity
      end

      get '/:username/comments' do
        authorized?
        @user = User.find_by_username params[:username]
        @user_comments =  Versioncomment.find_by_user_id @user.id
        @user_comments.each_with_index do |cmd, index|
          @user_comments[index][:user] = @user
          @user_comments[index][:product] = Product.find_by_key cmd.product_key
        end

        present @user_comments, with: Entities::CommentEntity
      end
    end
  end
end
