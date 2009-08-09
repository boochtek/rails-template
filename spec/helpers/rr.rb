# Use RR (Double Ruby) for stubbing and mocking.
require 'rr'
Spec::Runner.configure do |config|
  config.mock_with :rr
end

# Allows us to use a nice syntax like this:
#   subject.should have_received.foo(1)
