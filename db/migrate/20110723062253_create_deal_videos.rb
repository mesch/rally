class CreateDealVideos < ActiveRecord::Migration
  def self.up
    create_table :deal_videos do |t|
      t.integer     "deal_id"
      t.integer     "counter"
      t.string      "video_file_name"
      t.string      "video_content_type"
      t.integer     "video_file_size"
      t.boolean     "active",             :default => true
      t.timestamps
    end
    
    add_index :deal_videos, [:deal_id, :counter], :name => "deal_videos_by_deal_counter"
  end

  def self.down
    remove_index :deal_videos, "deal_videos_by_deal_counter"

    drop_table :deal_videos
  end
end
