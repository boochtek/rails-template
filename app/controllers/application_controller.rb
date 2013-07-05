# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Define the default layout.
  layout 'application'

  # Pull in some helpers.
  helper 'jquery'

  # Add CSRF protection, by adding hidden fields to forms, containing a token.
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Special case handling for RecordNotFound exceptions. We don't want to be notified of these exceptions.
  def rescue_action(exception)
    case exception
    when ActiveRecord::RecordNotFound
      render :text => 'Could not find the requested record!', :status => 404
    else
      super
    end
  end

end
