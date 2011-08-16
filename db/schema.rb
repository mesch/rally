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

ActiveRecord::Schema.define(:version => 20110808231657) do

  create_table "coupons", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deal_id"
    t.integer  "deal_code_id"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "coupons", ["deal_id"], :name => "index_coupons_on_deal_id"
  add_index "coupons", ["user_id"], :name => "index_coupons_on_user_id"

  create_table "deal_codes", :force => true do |t|
    t.integer  "deal_id"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "reserved",   :default => false
  end

  add_index "deal_codes", ["deal_id"], :name => "index_deal_codes_on_deal_id"

  create_table "deal_images", :force => true do |t|
    t.integer  "deal_id"
    t.integer  "counter"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.boolean  "active",             :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deal_images", ["deal_id", "counter"], :name => "deal_images_by_deal_counter"

  create_table "deal_videos", :force => true do |t|
    t.integer  "deal_id"
    t.integer  "counter"
    t.string   "video_file_name"
    t.string   "video_content_type"
    t.integer  "video_file_size"
    t.boolean  "active",             :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deal_videos", ["deal_id", "counter"], :name => "deal_videos_by_deal_counter"

  create_table "deals", :force => true do |t|
    t.integer  "merchant_id"
    t.string   "title"
    t.date     "start_date"
    t.date     "end_date"
    t.date     "expiration_date"
    t.integer  "deal_price_in_cents"
    t.integer  "deal_value_in_cents"
    t.integer  "max",                 :default => 0
    t.integer  "limit",               :default => 1
    t.text     "description"
    t.text     "terms"
    t.boolean  "active",              :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "min",                 :default => 0
    t.boolean  "published",           :default => false
  end

  add_index "deals", ["merchant_id"], :name => "index_deals_on_merchant_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "merchant_reports", :force => true do |t|
    t.integer  "merchant_id"
    t.string   "report_type"
    t.integer  "deal_id"
    t.datetime "start"
    t.datetime "end"
    t.string   "state"
    t.datetime "generated_at"
    t.string   "report_file_name"
    t.string   "report_content_type"
    t.integer  "report_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "merchant_subdomains", :force => true do |t|
    t.string   "subdomain"
    t.integer  "merchant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "merchants", :force => true do |t|
    t.string   "name"
    t.string   "username"
    t.string   "hashed_password"
    t.string   "email"
    t.string   "salt"
    t.string   "activation_code"
    t.boolean  "activated",                      :default => false
    t.string   "api_key"
    t.boolean  "active",                         :default => true
    t.string   "time_zone",                      :default => "Pacific Time (US & Canada)"
    t.string   "website"
    t.string   "contact_name"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.string   "phone_number"
    t.integer  "tax_id"
    t.string   "bank"
    t.string   "account_name"
    t.string   "routing_number"
    t.string   "account_number"
    t.string   "paypal_account"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.integer  "facebook_page_id",  :limit => 8
    t.boolean  "terms",                          :default => false
  end

  add_index "merchants", ["username"], :name => "index_merchants_on_username"

  create_table "order_payments", :force => true do |t|
    t.integer  "user_id"
    t.integer  "order_id"
    t.string   "gateway"
    t.string   "transaction_type"
    t.string   "confirmation_code"
    t.integer  "amount_in_cents"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "transaction_id"
  end

  add_index "order_payments", ["order_id"], :name => "index_order_payments_on_order_id"
  add_index "order_payments", ["user_id"], :name => "index_order_payments_on_user_id"

  create_table "orders", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deal_id"
    t.integer  "quantity",        :default => 0
    t.integer  "amount_in_cents", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",           :default => "CREATED"
    t.datetime "authorized_at"
    t.datetime "paid_at"
  end

  add_index "orders", ["user_id", "deal_id"], :name => "orders_by_user_deal"

  create_table "process_logs", :force => true do |t|
    t.string   "name"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "considered"
    t.integer  "successes"
    t.integer  "failures"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_actions", :force => true do |t|
    t.integer  "visitor_id"
    t.integer  "user_id"
    t.integer  "merchant_id"
    t.integer  "deal_id"
    t.string   "controller"
    t.string   "action"
    t.string   "method"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "hashed_password"
    t.string   "salt"
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "activation_code"
    t.boolean  "activated",                     :default => false
    t.boolean  "active",                        :default => true
    t.string   "time_zone",                     :default => "Pacific Time (US & Canada)"
    t.string   "mobile_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "balance_in_cents",              :default => 0
    t.integer  "facebook_id",      :limit => 8
  end

  add_index "users", ["email"], :name => "index_users_on_email"

  create_table "visitors", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
