class AddDealPublished < ActiveRecord::Migration
  def self.up
    add_column :deals,  "published", :boolean, :default => false
  end

  def self.down
    remove_column :deals, "published"
  end
end
