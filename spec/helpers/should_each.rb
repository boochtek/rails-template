# Got this from David Chelimsky: http://rubyforge.org/tracker/index.php?func=detail&aid=9304&group_id=797&atid=3152
# I love the idea. Not sure how error messages will work out, since they will show the element, not the collection.
# Usage example: (1..10).should_each be < 11
module Spec
  module Expectations
    module ObjectExpectations
      def should_each(matcher=:use_operator_matcher, &block)
        self.each {|item| ExpectationMatcherHandler.handle_matcher(item, matcher, &block)}
      end        
    end
  end
end
# Add should_each as a "should_method" that doesn't get added to internal classes.
module Spec
  module Example
    module ExampleGroupMethods
      def should_method?(method_name)
        !(method_name =~ /^should(_not|_each)?$/) &&
        method_name =~ /^should/ && 
          ( instance_method(method_name).arity == 0 ||
            instance_method(method_name).arity == -1 )
      end
    end
  end
end
