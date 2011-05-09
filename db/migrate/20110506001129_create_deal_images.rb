class CreateDealImages < ActiveRecord::Migration
  def self.up
    create_table :deal_images do |t|
      t.integer     "deal_id"
      t.integer     "counter"
      t.string      "image_file_name"
      t.string      "image_content_type"
      t.integer     "image_file_size"
      t.boolean     "active",             :default => true
      t.timestamps
    end
    
    add_index :deal_images, [:deal_id, :counter], :name => "deal_images_by_deal_counter"
  end

  def self.down
    remove_index :deal_images, "deal_images_by_deal_counter"

    drop_table :deal_images
  end
end
