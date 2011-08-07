class DealCode < ActiveRecord::Base
  validates_presence_of :deal_id, :code
  validates_length_of :code, :maximum => 40
  validates_uniqueness_of :code, :scope => :deal_id
  
  attr_protected :id
  
  belongs_to :deal
  
  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    p search
    p page
    p per_page
    paginate :per_page => per_page, :page => page,
             :conditions => ['deal_id = ?', "#{search}"],
             :order => 'created_at asc'
  end

end
