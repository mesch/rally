module DateHelper
  
  def verify_date(string)
    begin
      return Time.zone.parse(string) ? true : false
    rescue
      return false
    end
  end
  
end
