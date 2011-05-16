class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.integer       "user_id"
      t.integer       "deal_id"
      t.integer       "quantity",       :default => 1
      t.integer       "amount_in_cents"
      t.string        "confirmation_code"
      t.timestamps
    end
    
    add_index :orders, [:user_id, :deal_id], :name => "orders_by_user_deal"
  end

  def self.down
    remove_index :orders, "orders_by_user_deal"
    
    drop_table :orders
  end
end
