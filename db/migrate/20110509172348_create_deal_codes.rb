class CreateDealCodes < ActiveRecord::Migration
  def self.up
    create_table :deal_codes do |t|
      t.integer   "deal_id"
      t.string    "code"
      t.timestamps
    end
    
    add_index :deal_codes, :deal_id
  end

  def self.down
    remove_index :deal_codes, :deal_id

    drop_table :deal_codes
  end
end