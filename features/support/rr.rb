# Use RR (Double Ruby) for stubbing and mocking.
# Got these from http://rhnh.net/2008/10/01/integration-testing-with-cucumber-rspec-and-thinking-sphinx and http://blog.timurv.ru/2009/4/29/cucumber-with-rr-double-ruby

require 'rr'
Cucumber::Rails::World.send(:include, RR::Adapters::RRMethods)

Before do
  RR.reset
end

After do
  begin
    RR.verify
  ensure
    RR.reset
  end
end
