require 'rails_helper'

RSpec.describe 'solid_cache', type: :model do
  let(:solid_cache) { Rails.cache }
  let(:cache_key) { 'test_key' }
  let(:cache_value) { 'test_value' }

  before do
    solid_cache.clear # Ensure the cache is cleared before each test
  end

  # SolidCache::Store failsafe (app/models/solid_cache store) swallows transient
  # DB errors (e.g. SQLite lock contention under a saturated full-suite run) and
  # returns nil — retry briefly so such a transient miss does not flake the spec.
  def read_with_retry(key, attempts: 10, sleep_seconds: 0.05)
    attempts.times do
      value = solid_cache.read(key)
      return value if value
      sleep(sleep_seconds)
    end
    solid_cache.read(key)
  end

  describe 'cache configuration' do
    it 'uses the Rails cache store' do
      expect(solid_cache).to be_a(SolidCache::Store)
    end
  end

  describe 'basic caching behavior' do
    it 'stores and retrieves a value from the cache' do
      solid_cache.write(cache_key, cache_value)
      expect(read_with_retry(cache_key)).to eq(cache_value)
    end

    it 'returns nil for a non-existent key' do
      expect(solid_cache.read('non_existent_key')).to be_nil
    end
  end

  describe 'cache expiration' do
    it 'expires a key after the specified time' do
      solid_cache.write(cache_key, cache_value, expires_in: 1.second)
      expect(read_with_retry(cache_key)).to eq(cache_value)

      sleep(2) # Wait for the cache to expire
      expect(solid_cache.read(cache_key)).to be_nil
    end
  end

  describe 'cache clearing' do
    it 'clears a specific key from the cache' do
      solid_cache.write(cache_key, cache_value)
      solid_cache.delete(cache_key)
      expect(solid_cache.read(cache_key)).to be_nil
    end

    it 'clears all keys from the cache' do
      solid_cache.write('key1', 'value1')
      solid_cache.write('key2', 'value2')

      solid_cache.clear
      expect(solid_cache.read('key1')).to be_nil
      expect(solid_cache.read('key2')).to be_nil
    end
  end
end
