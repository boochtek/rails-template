# Global constants that apply to the site as a whole.
# Idea from http://www.smashingmagazine.com/2009/02/25/ruby-on-rails-tips/.

# Name (identifier) of the project. Generally the same name as the directory containing the project.
PROJECT_NAME = RAILS_ROOT.split('/').last

# Override these - they will be used in the default layout.
SITE_NAME = PROJECT_NAME.humanize
SITE_TITLE = SITE_NAME + ('production' == RAILS_ENV ? '' : " (#{RAILS_ENV.upcase})")

# It is highly recommended that you define this to your top-level URL. It will be used to create a CSS signature (http://archivist.incutio.com/viewlist/css-discuss/13291) for pages in your site.
SITE_URI = nil

# Years and name to list in copyright statements.
COPYRIGHT_YEARS = '2008, 2009'
COPYRIGHT_OWNER = ''

# Version of jQuery to use.
JQUERY_VERSION = '1.3.2'

# Google Analytics code. Set this to enable Google Analytics on the site.
GOOGLE_ANALYTICS_CODE = nil

# Google Webmaster Tools (http://www.google.com/webmasters/) code. Set this to verify that you control the site, so you can see how Google views your site.
GOOGLE_WEBMASTERS_CODE = nil

# Email exceptions to this list of addresses, if ExceptionNotifier is loaded.
EMAIL_EXCEPTIONS_TO = []
