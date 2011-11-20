class Share < ActiveRecord::Base

  validates_presence_of :user_id, :deal_id, :facebook_id
    
  attr_protected :id

  belongs_to :user
  belongs_to :deal

  # Paginate methods
  def self.search(search="", page=1, per_page=10)
    paginate :per_page => per_page, :page => page,
             :order => 'created_at desc'
  end

end
