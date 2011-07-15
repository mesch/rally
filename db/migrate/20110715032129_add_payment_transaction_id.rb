class AddPaymentTransactionId < ActiveRecord::Migration
  def self.up
    add_column :order_payments, :transaction_id, :string
  end

  def self.down
    remove_column :order_payments, :transaction_id
  end
end
