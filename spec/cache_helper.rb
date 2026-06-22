RSpec.configure do |config|
  config.before(:each) do
    Rails.cache.clear
    Rails.local_cache.clear  rescue nil
    Rails.global_cache.clear rescue nil
  end
end
