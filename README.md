BoochTek Rails Template
=======================

This is my Rails template, used to create new Ruby on Rails applications.
In many ways, this is a collection of my personal knowledge, opinions, and best practices regarding Rails.

The template will prompt you to ask if you want some optional components.
These include ActiveRecord, ActiveResource, ActionMailer, and more.

The template can link to a local copy of Edge Rails, if available.

Uses RSpec, Shoulda, Bogus, and Factory Girl for testing.

Slim, HAML, or ERB can be used for view templates.


Usage
-----

~~~ bash
APP_NAME='name_of_your_new_rails_app'
RUBY_VERSION='2.3.1'
RAILS_VERSION='5.0.0.1'
RAILS_TEMPLATE='https://raw.githubusercontent.com/boochtek/rails-template/master/rails-template.rb'
chruby $RUBY_VERSION
gem install rake bundler # You might want to install some utilities as well, such as pry, awesome_print, hirb, and wirble.
gem install railties --version $RAILS_VERSION --prerelease
rails "_${RAILS_VERSION}_" new $APP_NAME --template $RAILS_TEMPLATE --database=postgresql --skip-test-unit --skip-action-cable
~~~

Note that you might have some problems installing newer versions of Ruby.
I had to do this for Ruby 2.1.3:

~~~ bash
CC=/usr/bin/gcc /usr/local/Cellar/ruby-install/0.4.3/bin/ruby-install --md5 02b7da3bb06037c777ca52e1194efccb ruby 2.1.3
~~~

It's also possible to download a copy of this repository, and refer to the template file via a file path:

~~~ bash
RAILS_TEMPLATE='/home/booch/projects/rails-template/rails-template.rb'
~~~


Credits
-------

I got some of these ideas and code from other templates, including http://github.com/jeremymcanally/rails-templates/.


Copyright
---------

Copyright (c) 2008,2009,2013,2014 BoochTek, LLC


License
-------

This software is licensed under the MIT License.
