class RemoveUserUsername < ActiveRecord::Migration
  def self.up
    remove_column :users, :username
    remove_index :users, :username
  end

  def self.down
    add_column :users, :username, :string
    add_index :user, :username
  end
end
