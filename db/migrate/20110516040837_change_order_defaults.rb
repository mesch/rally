class ChangeOrderDefaults < ActiveRecord::Migration
  def self.up
    change_column :orders, :quantity, :integer, :default => 0
    change_column :orders, :amount_in_cents, :integer, :default => 0
  end

  def self.down
    change_column :orders, :quantity, :integer, :default => 1
    change_column :orders, :amount_in_cents, :integer
  end
end
