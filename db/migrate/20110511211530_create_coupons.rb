class CreateCoupons < ActiveRecord::Migration
  def self.up
    create_table :coupons do |t|
      t.integer       "user_id"
      t.integer       "deal_id"
      t.integer       "deal_code_id"
      t.integer       "order_id"
      t.timestamps
    end
    
    add_index :coupons, :user_id
    add_index :coupons, :deal_id
  end

  def self.down
    remove_index :coupons, :user_id
    remove_index :coupons, :deal_id
    
    drop_table :coupons
  end
end
