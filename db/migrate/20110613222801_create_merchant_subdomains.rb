class CreateMerchantSubdomains < ActiveRecord::Migration
  def self.up
    create_table :merchant_subdomains do |t|
      t.string    "subdomain"
      t.integer   "merchant_id"
      t.timestamps
    end
  end

  def self.down
    drop_table :merchant_subdomains
  end
end
