class AddMerchantFbColumns < ActiveRecord::Migration
  def self.up
    add_column :merchants, :logo_file_name, :string
    add_column :merchants, :logo_content_type, :string
    add_column :merchants, :logo_file_size, :integer
    add_column :merchants, :facebook_page_id, :integer, :limit => 8
  end

  def self.down
    remove_column :merchants, :logo_file_name
    remove_column :merchants, :logo_content_type
    remove_column :merchants, :logo_file_size
    remove_column :merchants, :facebook_page_id
  end
end
