class AddUserFacebookId < ActiveRecord::Migration
  def self.up
    add_column :users, :facebook_id, :integer, :limit => 8
  end

  def self.down
    remove_column :users, :facebook_id
  end
end
