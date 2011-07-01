module ErrorHelper
  
  def pp_errors(error_hash)
    output = ""
    for key in error_hash.keys
     output << "#{key}: [#{error_hash[key].join(", ")}]. "
    end
    return output
  end
  
end