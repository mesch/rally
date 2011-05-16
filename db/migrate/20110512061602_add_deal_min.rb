class AddDealMin < ActiveRecord::Migration
  def self.up
    add_column :deals, :min, :integer, :default => 0
  end

  def self.down
    remove_column :deals, :min
  end
end
