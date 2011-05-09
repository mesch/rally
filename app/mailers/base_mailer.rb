class BaseMailer < ActionMailer::Base

  helper :application
        
  default :from => OPTIONS[:email_from], :return_path => OPTIONS[:email_return_path]

end