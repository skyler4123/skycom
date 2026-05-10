RSpec.configure do |config|
  # ... other config ...

  config.before(:each) do
    # This clears whatever store is defined in config/environments/test.rb
    Rails.cache.clear
  end
end
