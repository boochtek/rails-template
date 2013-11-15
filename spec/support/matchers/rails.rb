RSpec::Matchers.define :be_a_valid do |expected|
  description { "be a valid model object" }
  failure_message_for_should do |actual|
    message = ''
    message += "object expected to be a(n) #{expected.name} but was a(n) #{actual.class.name}\n" unless actual.is_a?(expected)
    message += "#{actual.class.name} expected to be valid but had errors:\n  #{actual.errors.full_messages.join("\n  ")}" unless actual.valid?
  end
  failure_message_for_should_not do |actual|
    message = ''
    message += "object expected to NOT be a(n) #{expected.name} but was a(n) #{expected.name} (#{actual.class.name})\n" if actual.is_a?(expected)
    message += "#{actual.class} expected to be invalid but was valid.\n" if actual.valid?
  end
  match do |actual|
    actual.valid? and actual.is_a?(expected)
  end
end



module RSpec
  module Rails
    module Matchers

      # I wrote these to make it easy to specify invalid and valid attributes in a list, to "declare" good and bad attribute values to test. (Craig Buchek)
      # Example: @quote_section.should be_valid_with(:name, ['Craig', 'Bob', 'a' * 64, 'John Johnson'])
      # Example: @quote_section.should be_invalid_with(:name, [nil, '', 'a' * 65, 12.2])
      # TODO: Can I replace should be_invalid_with() with should_not be_valid_with()? I don't think so.
      class BeValidWith  #:nodoc:
        def initialize(attrib, array_of_values)
          @attrib = attrib
          array_of_values = [array_of_values] if !array_of_values.respond_to?(:[]) # Allow a single value in place of an array.
          @array_of_values = array_of_values
        end
        def matches?(model)
          @model = model
          attrib_set = (@attrib.to_s + '=').to_sym
          @array_of_values.each do |value|
            @model.send(attrib_set, value)
            if !@model.valid?
              @invalid_value = value
              return false
            end
          end
          return true
        end
        def failure_message_for_should
          "#{@model.class} expected to be valid when #{@attrib}=#{@invalid_value.inspect} but had errors:\n  #{@model.errors.full_messages.join("\n  ")}"
        end
        def description
          'be valid with given attribute set to each/any of the given values'
        end
      end
      class BeInvalidWith  #:nodoc:
        def initialize(attrib, array_of_values)
          @attrib = attrib
          array_of_values = [array_of_values] if !array_of_values.respond_to?(:[]) # Allow a single value in place of an array.
          @array_of_values = array_of_values
        end
        def matches?(model)
          @model = model
          attrib_set = (@attrib.to_s + '=').to_sym
          @array_of_values.each do |value|
            @model.send(attrib_set, value)
            if @model.valid?
              @valid_value = value
              return false
            end
          end
          return true
        end
        def failure_message_for_should
          "#{@model.class} expected to be invalid when #{@attrib}=#{@valid_value.inspect} but had no errors\n"
        end
        def description
          'be invalid with given attribute set to each/any of the given values'
        end
      end
      def be_valid_with(attrib, array_of_values)
        BeValidWith.new(attrib, array_of_values)
      end
      def be_invalid_with(attrib, array_of_values)
        BeInvalidWith.new(attrib, array_of_values)
      end

      # Got this one from http://www.elevatedrails.com/articles/2007/05/09/custom-expectation-matchers-in-rspec/
      class HaveErrorOn
        def initialize(field)
          @field=field
        end
        def matches?(model)
          @model=model
          @model.valid?
          !@model.errors.on(@field).nil?
        end
        def description
          "have error(s) on #{@field}"
        end
        def failure_message_for_should
          "expected to have error(s) on #{@field} but doesn't"
        end
        def failure_message_for_should_not
          "expected NOT to have errors on #{@field} but does have an error: #{@model.errors.on(@field)}"
        end
      end
      def have_error_on(field)
        HaveErrorOn.new(field)
      end
      def have_errors_on(field)
        HaveErrorOn.new(field)
      end
    end
  end
end
