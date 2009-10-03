# This provides an inverse of [a,b,c].should include(x) -- x.should be_in([a, b, c]); (Craig Buchek)
# NOTE: If we define Object#in? we don't need this RSpec helper!

Spec::Matchers.define :be_in do |expected|
  description { "be a member of (included in) #{expected}" }
  failure_message_for_should { |actual| "expected that #{actual} would be in #{expected}" }
  failure_message_for_should_not { |actual| "expected that #{actual} would not be in #{expected}" }
  match do |actual|
    expected.include?(actual)
  end
end
