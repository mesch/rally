class CreateMerchantReports < ActiveRecord::Migration
  def self.up
    create_table :merchant_reports do |t|
      t.integer     "merchant_id"
      t.string      "report_type"
      t.integer     "deal_id"
      t.datetime    "start"
      t.datetime    "end"
      t.string      "state"
      t.datetime    "generated_at"
      t.string      "report_file_name"
      t.string      "report_content_type"
      t.integer     "report_file_size"
      t.timestamps
    end
  end

  def self.down
    drop_table :merchant_reports
  end
end
