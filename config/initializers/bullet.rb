if File.basename($0) != 'rake' && ['development', 'test', 'cucumber'].include? Rails.env
  Bullet.enable = true
  # Log to the standard Rails log as well as log/bullet.log and the browser's console log.
  Bullet.bullet_logger = true
  Bullet.rails_logger = true
  Bullet.console = true
  begin
    # Use Growl if we have it.
    require 'ruby-growl'
    Bullet.growl = true
  rescue MissingSourceFile
    # If we don't have Growl, use a JavaScript alert instead.
    Bullet.alert = true
  end
end
