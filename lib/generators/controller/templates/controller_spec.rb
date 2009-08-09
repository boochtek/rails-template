require File.expand_path(File.dirname(__FILE__) + '<%= '/..' * class_nesting_depth %>/../spec_helper')

describe <%= class_name %>Controller do

  #Delete these examples and add some real ones
  it "should use <%= class_name %>Controller" do
    controller.should be_an_instance_of(<%= class_name %>Controller)
  end

  describe "routes" do
    it { should route(:get, '/<%= class_name.downcase.pluralize %>/1').to(:action => 'show', :id => '1') }
  end



<% unless actions.empty? -%>
<% for action in actions -%>

  describe "GET '<%= action %>'" do
    subject { controller }
    before(:each) do
      get '<%= action %>', :id => <%= class_name %>.first.to_param
    end
    # For full list of Shoulda ActionController macros, see http://dev.thoughtbot.com/shoulda/classes/Shoulda/ActionController/Matchers.html
    it { should assign_to(:user) }
    it { should respond_with(:success) }
    it { should_not set_the_flash) }
  end

<% end -%>
<% end -%>
end
