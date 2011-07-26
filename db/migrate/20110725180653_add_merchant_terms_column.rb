class AddMerchantTermsColumn < ActiveRecord::Migration
  def self.up
    add_column :merchants, "terms", :boolean, :default => false
  end

  def self.down
    remove_column :merchants, "terms"
  end
end
