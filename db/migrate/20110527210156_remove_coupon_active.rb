class RemoveCouponActive < ActiveRecord::Migration
  def self.up
    remove_column :coupons, "active"
  end

  def self.down
    add_column :coupons,  "active", :boolean, :default => false
  end
end
