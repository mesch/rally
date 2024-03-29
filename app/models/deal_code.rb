class DealCode < ActiveRecord::Base
  validates_presence_of :deal_id, :code
  validates_uniqueness_of :code, :scope => [:deal_id, :incentive]
  
  attr_protected :id
  
  belongs_to :deal
  
  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :conditions => ['deal_id = ?', "#{search}"],
             :order => 'created_at asc'
  end

end
