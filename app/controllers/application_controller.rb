# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Fall back to app/views/default if view file cannot be found.
  include BoochTek::Rails::DefaultViews

  # Define the default layout.
  layout 'application'

  # Add CSRF protection, by adding hidden fields to forms, containing a token.
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Ensure that sensitive data doesn't get logged.
  filter_parameter_logging :password, :password_confirmation, :confirm_password, :ssn, :social_security_number, :credit_card, :credit_card_number, :cvv, :cvv2

  # Activate exception handlers, if we've got them, and we're in production.
  if ['production', 'staging'].include? ENV['RAILS_ENV']
    if const_defined?('HoptoadNotifier') and Hoptoad.api_key
      include HoptoadNotifier::Catcher
    end
    if const_defined?('ExceptionNotifiable')
      include ExceptionNotifiable
      ExceptionNotifier.exception_recipients = EMAIL_EXCEPTIONS_TO
    end
  end

  # Special case handling for RecordNotFound exceptions. We don't want to send emails for these!
  def rescue_action(exception)
    case exception
    when ActiveRecord::RecordNotFound
      render :text => 'Could not find the requested record!', :status => 404
    else
      super
    end
  end

end
