class AddUserBalance < ActiveRecord::Migration
  def self.up
    add_column :users, "balance_in_cents", :integer, :default => 0
  end

  def self.down
    remove_column :users, "balance_in_cents"
  end
end
