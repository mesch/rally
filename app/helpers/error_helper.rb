module ErrorHelper
  
  def pp_errors(error_hash)
    output = ""
    for key in error_hash.keys
     output << "<p>#{key}: #{error_hash[key].join(", ")}.</p>"
    end
    return output
  end
  
end