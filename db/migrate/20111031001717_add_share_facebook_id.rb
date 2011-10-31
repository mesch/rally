class AddShareFacebookId < ActiveRecord::Migration
  def self.up
    add_column :shares, :facebook_id, :integer, :limit => 8
  end

  def self.down
    remove_column :shares, :facebook_id
  end
end
