# Load the rails application
require File.expand_path('../application', __FILE__)

# Add the common environment file which defines OPTIONS hash
require File.expand_path(File.join(File.dirname(__FILE__),'environments','common.rb'))

# Initialize the rails application
Rally::Application.initialize!

