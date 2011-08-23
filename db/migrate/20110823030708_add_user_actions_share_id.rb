class AddUserActionsShareId < ActiveRecord::Migration
  def self.up
    add_column :user_actions, :share_id, :integer
  end

  def self.down
    remove_column :user_actions, :share_id
  end
end
