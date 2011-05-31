class CreateOrderPayments < ActiveRecord::Migration
  def self.up
    create_table :order_payments do |t|
      t.integer     "user_id"
      t.integer     "order_id"
      t.string      "gateway"
      t.string      "transaction_type"
      t.string      "confirmation_code"
      t.integer     "amount_in_cents"
      t.timestamps
    end
    
    add_index :order_payments, :user_id
    add_index :order_payments, :order_id
  end

  def self.down
    remove_index :order_payments, :user_id
    remove_index :order_payments, :order_id
    
    drop_table :order_payments
  end
end
