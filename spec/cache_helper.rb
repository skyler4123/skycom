RSpec.configure do |config|
  config.before(:each) do
    Rails.cache.clear              rescue nil
    Rails.local_cache.clear        rescue nil
    Rails.global_cache.clear       rescue nil
    Rails.global_session_cache.clear rescue nil
  end
end
