# Global constants that apply to the site as a whole.
# Idea from http://www.smashingmagazine.com/2009/02/25/ruby-on-rails-tips/.

# Name (identifier) of the project. Generally the same name as the directory containing the project.
PROJECT_NAME = RAILS_ROOT.split('/').last

# Override these - they will be used in the default layout.
SITE_NAME = PROJECT_NAME.humanize
SITE_TITLE = SITE_NAME + ('production' == RAILS_ENV ? '' : " (#{RAILS_ENV.upcase})")

# Years listed in copyright statements.
COPYRIGHT_YEARS = '2008, 2009'
COPYRIGHT_OWNER = ''

# Version of jQuery to use.
JQUERY_VERSION = '1.3.2'
