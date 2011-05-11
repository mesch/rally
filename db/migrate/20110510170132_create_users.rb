class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string      "username"
      t.string      "hashed_password"
      t.string      "salt"
      t.string      "email"
      t.string      "first_name"
      t.string      "last_name"
      t.string      "activation_code"
      t.boolean     "activated",  :default => false
      t.boolean     "active",     :default => true
      t.string      "time_zone",  :default => "Pacific Time (US & Canada)"
      t.string      "mobile_number"
      t.timestamps
    end
    
    add_index :users, :username
    add_index :users, :email
  end

  def self.down
    remove_index :users, :username
    remove_index :users, :email
    
    drop_table :users
  end
end
