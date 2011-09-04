require "fastercsv"

class MerchantReport < ActiveRecord::Base
  # States
  GENERATING = 'GENERATING'
  GENERATED = 'GENERATED'
  # Report Types
  COUPON_REPORT = 'COUPON_REPORT'
  REPORT_TYPES = [ COUPON_REPORT ]
  # Upload params
  MAX_REPORT_SIZE = 100.megabytes # Max size
  CONTENT_TYPES = ['text/csv']

  validate :required_filters

  #validates_attachment_presence :report
  validates_attachment_size :report, :less_than => MAX_REPORT_SIZE, :if => lambda { report.dirty? }
  validates_attachment_content_type :report, :content_type => CONTENT_TYPES, :if => lambda { report.dirty? }

  validates_presence_of :merchant_id, :report_type, :state
  validates_inclusion_of :state, :in => [ GENERATING, GENERATED ]
  validates_inclusion_of :report_type, :in => REPORT_TYPES

  attr_protected :id

  belongs_to :merchant

  has_attached_file :report, {
    
  }.merge(OPTIONS[:paperclip_report_storage_options])

  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :conditions => ['merchant_id = ?', "#{search}"],
             :order => 'created_at desc'
  end

  def required_filters
    case self.report_type
    when COUPON_REPORT
      errors.add(:base, "Deal ID must be defined for coupon reports") unless self.deal_id
    end
  end

  def generate_file_name(generated_at)
    file_name = ""
    case self.report_type
    when COUPON_REPORT
      file_name = "coupon_report_#{self.merchant_id}_#{self.deal_id}_#{generated_at.strftime(OPTIONS[:time_format_file])}.csv"
    end
    return file_name
  end
  
  def column_names
    column_names = []
    case self.report_type
    when COUPON_REPORT
      column_names = ["coupon_code", "email", "first_name", "last_name", "authorized_at"]
    end
    return column_names
  end

  def generate_header()
    case self.report_type
    when COUPON_REPORT
      header = "Filters: Merchant ID (#{self.merchant_id}), Deal ID (#{self.deal_id})"
    end
    return header
  end

  def generate_results(options ={})
    results = []
    case self.report_type
    when COUPON_REPORT
      # Select codes
      if options[:all]
        results = DealCode.find(:all, 
                              :select => "deal_codes.code, users.email, users.first_name, users.last_name, coupons.created_at as authorized_at",
                              :joins => "left join coupons on deal_codes.id = coupons.deal_code_id left join users on coupons.user_id = users.id",
                              :conditions => ["deal_codes.deal_id = ?", self.deal_id],
                              :order => "deal_codes.reserved DESC, deal_codes.code ASC") 
      else
        results = DealCode.find(:all, 
                              :select => "deal_codes.code, users.email, users.first_name, users.last_name, coupons.created_at as authorized_at",
                              :joins => "join coupons on deal_codes.id = coupons.deal_code_id join users on coupons.user_id = users.id",
                              :conditions => ["deal_codes.deal_id = ?", self.deal_id],
                              :order => "deal_codes.code ASC")
      end
    end
    return results
  end
  
  def generate_row(data)
    row = ""
    case self.report_type
    when COUPON_REPORT
        authorized_at = data.authorized_at ? Time.zone.parse(data.authorized_at).strftime(OPTIONS[:time_format]) : ""
        row = [data.code, data.email, data.first_name, data.last_name, authorized_at]
    end
    return row
  end

  def generate_report(all=false)
    generated_at = Time.zone.now
    file_name = self.generate_file_name(generated_at)
    begin
      results = self.generate_results(:all => all)

      csv_file_path = File.join(OPTIONS[:temp_file_directory], file_name)
      FasterCSV.open(csv_file_path, "w") do |csv|
        # write generic header
        csv << ["Generated At: #{generated_at.strftime(OPTIONS[:time_format])}"]
        # write report-specific header
        csv << [self.generate_header]
        # add column names
        csv << self.column_names
        # add data
        for result in results
          csv << self.generate_row(result)
        end
      end

      # Save file using paperclip
      local = File.open(csv_file_path)
      self.report = local
      local.close

      # Delete local file
      File.delete(csv_file_path)
 
      # Update state
      self.update_attributes!(:state => GENERATED, :generated_at => generated_at)
      return true
    rescue => e
      logger.error "MerchantReport.generate_report Failed: Merchant Report #{self.inspect} #{e}"
    end
    return false
  end

end
