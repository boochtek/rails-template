# Allow use of FactoryGirl factories from Cucumber.
Dir[File.expand_path(File.join("#{Rails.root}/spec/factories","**","*.rb"))].each {|f| require f}
