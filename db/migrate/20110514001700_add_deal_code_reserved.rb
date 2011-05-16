class AddDealCodeReserved < ActiveRecord::Migration
  def self.up
    add_column :deal_codes, "reserved", :boolean, :default => false
  end

  def self.down
    remove_column :deal_codes, "reserved"
  end
end
