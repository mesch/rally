class AddCouponActive < ActiveRecord::Migration
  def self.up
    add_column :coupons,  "active", :boolean, :default => false
  end

  def self.down
    remove_column :coupons, "active"
  end
end
