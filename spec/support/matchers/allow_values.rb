# Shoulda gives us this:
#   it { should_not allow_value('bad').for(:isbn) }
#   it { should allow_value("isbn 1 2345 6789 0").for(:isbn) }
# We want to allow these:
#   its(:isbn) { should_not allow_values('bad', 'another_bad_isbn', nil)
#   its(:isbn) { should allow_values("isbn 1 2345 6789 0", "1 2345 6789 0", "1234567890") }
# We're currently here:
#   it { should_not allow_values_for(:isbn, 'bad', 'another_bad_isbn', nil)
#   it { should allow_values_for(:isbn, "isbn 1 2345 6789 0", "1 2345 6789 0", "1234567890") }
# I don't think we can get to its(:isbn), because we no longer have access to SET the isbn.
#   We might be able to get at it from description, description_args, or send(:description_parts).reverse.find {|part| part.is_a?(Symbol)}.
#     Or perhaps override its() to record the attribute name, like Remarkable does for describe: http://github.com/carlosbrando/remarkable/blob/master/remarkable_activerecord/lib/remarkable_activerecord/describe.rb.
# BTW, I'm pretty sure that I developed this independently from http://remarkable.rubyforge.org/activerecord/classes/Remarkable/ActiveRecord/Matchers.html#M000020
#   But I may just use his version instead.




# TODO: Implement this.
if false
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
end


module Spec
  module Rails
    module Matchers

      # I wrote these to make it easy to specify invalid and valid attributes in a list, to "declare" good and bad attribute values to test. (Craig Buchek)
      # Example: @quote_section.should be_valid_with(:name, ['Craig', 'Bob', 'a' * 64, 'John Johnson'])
      # Example: @quote_section.should be_invalid_with(:name, [nil, '', 'a' * 65, 12.2])
      # TODO: Can I replace should be_invalid_with() with should_not be_valid_with()? I don't think so.
      class AllowValuesFor  #:nodoc:
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
      def allow_values_for(attrib, *array_of_expected_values)
        AllowValuesFor.new(attrib, *array_of_expected_values)
      end
    end
  end
end
