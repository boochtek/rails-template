require File.expand_path(File.dirname(__FILE__) + '<%= '/..' * class_nesting_depth %>/../spec_helper')

describe <%= class_name %> do
  before(:each) do
    @<%= file_name %> = <%= class_name %>.new
  end

  subject { @<%= file_name %> }

  # For a full list of Shoulda ActiveRecord matchers, see http://dev.thoughtbot.com/shoulda/classes/Shoulda/ActiveRecord/Matchers.html
  it { should belong_to(:account) }
  it { should have_many(:posts) }
  it { should validate_presence_of(:email) }
  it { should allow_value("test@example.com").for(:email) }
  it { should_not allow_value("test").for(:email) }
  it { should_not allow_mass_assignment_of(:salt, :hashed_password) }
  its(:title) { should allow_values('this is a title', 'Title', 't') }

end
