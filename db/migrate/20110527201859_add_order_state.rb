class AddOrderState < ActiveRecord::Migration
  def self.up
    remove_column :orders, :confirmation_code
    add_column :orders, :state, :string, :default => Order::CREATED
  end

  def self.down
    add_column :orders, :confirmation_code, :string
    remove_column :orders, :state
  end
end
