module JqueryHelper
  # Pull in jQuery from Google (unless dev/test, in which case pull the local copy).
  def jquery_include_tag
    if %w(development test).include?(Rails.env)
      javascript_include_tag "jquery-#{JQUERY_VERSION}.js"
    else
      javascript_include_tag "http://ajax.googleapis.com/ajax/libs/jquery/#{JQUERY_VERSION}/jquery.min.js"
    end
  end
end
