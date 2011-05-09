class CreateMerchants < ActiveRecord::Migration
  def self.up
    create_table :merchants do |t|
      t.string      "name"
      t.string      "username"
      t.string      "hashed_password"
      t.string      "email"
      t.string      "salt"
      t.string      "activation_code"
      t.boolean     "activated",  :default => false
      t.string      "api_key"
      t.boolean     "active",     :default => true
      t.string      "time_zone",  :default => "Pacific Time (US & Canada)"
      t.string      "website"
      t.string      "contact_name"
      t.string      "address1"
      t.string      "address2"
      t.string      "city"
      t.string      "state"
      t.string      "zip"
      t.string      "country"
      t.string      "phone_number"
      t.integer     "tax_id"
      t.string      "bank"
      t.string      "account_name"
      t.string      "routing_number"
      t.string      "account_number"
      t.string      "paypal_account"
      t.timestamps
    end
    
    add_index :merchants, :username
  end

  def self.down
    remove_index :merchants, :username
    
    drop_table :merchants
  end
end