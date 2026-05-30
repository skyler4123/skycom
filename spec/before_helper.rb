# spec/spec_helper.rb
require 'rspec/retry'

RSpec.configure do |config|
  # Clear Faker's unique generator between each test to prevent username
  # pool exhaustion across the suite. Faker::UniqueGenerator maintains
  # global state that outlives transactional fixture rollbacks.
  config.before(:each) do
    Faker::UniqueGenerator.clear
  end
end
