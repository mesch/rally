class AddDealCodeIncentive < ActiveRecord::Migration
  def self.up
    add_column :deal_codes, "incentive", :boolean, :default => false
  end

  def self.down
    remove_column :deal_codes, "incentive"
  end
end
