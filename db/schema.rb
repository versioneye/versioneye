# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120301021814) do

  create_table "followers", :force => true do |t|
    t.integer  "user_id"
    t.string   "product_id",   :limit => 50, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "notification"
  end

  add_index "followers", ["product_id"], :name => "index_followers_on_product_id"
  add_index "followers", ["user_id", "product_id"], :name => "index_followers_on_user_id_and_product_id", :unique => true
  add_index "followers", ["user_id"], :name => "index_followers_on_user_id"

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "unsigneduser_id"
    t.string   "product_id",      :limit => 50,                    :null => false
    t.string   "version",      :limit => 50,                    :null => false
    t.boolean  "read",                          :default => false
    t.boolean  "sent_email",                    :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifications", ["read"], :name => "index_notifications_on_read"
  add_index "notifications", ["user_id"], :name => "index_notifications_on_user_id"
  add_index "notifications", ["version"], :name => "index_notifications_on_version"

  create_table "users", :force => true do |t|
    t.string   "username",           :limit => 50,                           :null => false
    t.string   "fullname",           :limit => 50,                           :null => false
    t.string   "email",              :limit => 254,                          :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password",                                         :null => false
    t.string   "salt",                                                       :null => false
    t.boolean  "admin",                             :default => false
    t.string   "fb_id",              :limit => 100
    t.string   "verification"
    t.string   "privacy_products",                  :default => "everybody"
    t.string   "privacy_comments",                  :default => "everybody"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["fb_id"], :name => "index_users_on_fb_id"
  add_index "users", ["username"], :name => "index_users_on_username", :unique => true

  create_table "versioncomments", :force => true do |t|
    t.integer  "user_id",                                 :null => false
    t.string   "product_key",                             :null => false
    t.string   "version",                                 :null => false
    t.integer  "rate"
    t.text     "comment",                                 :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "prod_name",   :default => "product name"
  end

  add_index "versioncomments", ["product_key", "version"], :name => "index_versioncomments_on_product_and_version"

end
