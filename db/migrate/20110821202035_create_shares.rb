class CreateShares < ActiveRecord::Migration
  def self.up
    create_table :shares do |t|
      t.integer       "user_id"
      t.integer       "deal_id"
      t.boolean       "posted",     :default => false
      t.integer       "post_id",    :limit => 8
      t.timestamps
    end
  end

  def self.down
    drop_table :shares
  end
end
