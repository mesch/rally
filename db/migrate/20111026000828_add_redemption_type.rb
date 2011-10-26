class AddRedemptionType < ActiveRecord::Migration
  def self.up
    add_column :merchants, "redemption_type", :string, :default => "COUPON_CODE"
  end

  def self.down
    remove_column :merchants, "redemption_type"
  end
end