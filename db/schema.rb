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

ActiveRecord::Schema.define(:version => 20110516040837) do

  create_table "coupons", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deal_id"
    t.integer  "deal_code_id"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",       :default => false
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
    t.string   "video"
    t.boolean  "active",              :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "min",                 :default => 0
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

  create_table "merchants", :force => true do |t|
    t.string   "name"
    t.string   "username"
    t.string   "hashed_password"
    t.string   "email"
    t.string   "salt"
    t.string   "activation_code"
    t.boolean  "activated",       :default => false
    t.string   "api_key"
    t.boolean  "active",          :default => true
    t.string   "time_zone",       :default => "Pacific Time (US & Canada)"
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
  end

  add_index "merchants", ["username"], :name => "index_merchants_on_username"

  create_table "orders", :force => true do |t|
    t.integer  "user_id"
    t.integer  "deal_id"
    t.integer  "quantity",          :default => 0
    t.integer  "amount_in_cents",   :default => 0
    t.string   "confirmation_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orders", ["user_id", "deal_id"], :name => "orders_by_user_deal"

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "hashed_password"
    t.string   "salt"
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "activation_code"
    t.boolean  "activated",        :default => false
    t.boolean  "active",           :default => true
    t.string   "time_zone",        :default => "Pacific Time (US & Canada)"
    t.string   "mobile_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "balance_in_cents", :default => 0
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["username"], :name => "index_users_on_username"

end
