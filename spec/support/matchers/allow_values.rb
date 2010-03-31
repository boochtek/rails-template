# Shoulda gives us this:
#   it { should_not allow_value('bad').for(:isbn) }
#   it { should allow_value("isbn 1 2345 6789 0").for(:isbn) }
# We want to allow these:
#   its(:isbn) { should_not allow_values('bad', 'another_bad_isbn', nil)
#   its(:isbn) { should allow_values("isbn 1 2345 6789 0", "1 2345 6789 0", "1234567890") }

# TODO: Implement this.
Spec::Matchers.define :allow_values do |attrib, *expected|
  description { "be valid with given attribute set to each/any of the given values" }
  failure_message_for_should { |actual| "#{actual.class} expected to be valid but had errors:\n  #{actual.errors.full_messages.join("\n  ")}" }
  failure_message_for_should_not { |actual| "expected that #{actual.class} would be invalid, but it was valid" }
  match do |actual|
    attrib_setter = (attrib.to_s + '=')
    expected.each do |value|
      actual.send(attrib_setter, value)
      if !actual.valid?
        return false
      end
    end
    return true
  end
end


module Spec
  module Rails
    module Matchers

      # I wrote these to make it easy to specify invalid and valid attributes in a list, to "declare" good and bad attribute values to test. (Craig Buchek)
      # Example: @quote_section.should be_valid_with(:name, ['Craig', 'Bob', 'a' * 64, 'John Johnson'])
      # Example: @quote_section.should be_invalid_with(:name, [nil, '', 'a' * 65, 12.2])
      # TODO: Can I replace should be_invalid_with() with should_not be_valid_with()? I don't think so.
      class AllowValues  #:nodoc:
        def initialize(attrib, *array_of_expected_values)
          @attrib = attrib
          @expected = array_of_expected_values
        end
        def matches?(actual)
          @actual = actual
          attrib_set = (@attrib.to_s + '=').to_sym
          @expected.each do |value|
            @actual.send(attrib_set, value)
            if !@actual.valid?
              @invalid_value = value
              return false
            end
          end
          return true
        end
        def failure_message_for_should
          "#{@actual.class} expected to be valid when #{@attrib}=#{@invalid_value.inspect} but had errors:\n  #{@actual.errors.full_messages.join("\n  ")}"
        end
        def description
          'be valid with given attribute set to each/any of the given values'
        end
      end
      def allow_values(attrib, *array_of_expected_values)
        AllowValues.new(attrib, *array_of_expected_values)
      end
    end
  end
end
