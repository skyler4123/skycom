# spec/system/local_and_global_cache_spec.rb
require "rails_helper"

RSpec.describe "Local & Global Cache", type: :system do
  after(:each) do
    Rails.local_cache.delete("rspec_local_key")
    Rails.local_cache.delete("rspec_local_fetch_key")
    Rails.local_cache.delete("rspec_independent_key")
    Rails.global_cache.delete("rspec_global_key")
    Rails.global_cache.delete("rspec_global_fetch_key")
    Rails.global_cache.delete("rspec_independent_key")
  end

  describe "Rails.local_cache (Solid Cache / SQLite)" do
    it "reads and writes string values" do
      Rails.local_cache.write("rspec_local_key", "hello local")
      expect(Rails.local_cache.read("rspec_local_key")).to eq("hello local")
    end

    it "deletes values" do
      Rails.local_cache.write("rspec_local_key", "to delete")
      Rails.local_cache.delete("rspec_local_key")
      expect(Rails.local_cache.read("rspec_local_key")).to be_nil
    end

    it "fetches and caches a block result" do
      result = Rails.local_cache.fetch("rspec_local_fetch_key", expires_in: 60) { "computed" }
      expect(result).to eq("computed")

      cached = Rails.local_cache.read("rspec_local_fetch_key")
      expect(cached).to eq("computed")
    end

    it "returns cached value on subsequent fetch" do
      call_count = 0
      Rails.local_cache.fetch("rspec_local_fetch_key", expires_in: 60) { call_count += 1; "first" }
      result = Rails.local_cache.fetch("rspec_local_fetch_key", expires_in: 60) { call_count += 1; "second" }

      expect(result).to eq("first")
      expect(call_count).to eq(1)
    end

    it "checks key existence" do
      expect(Rails.local_cache.exist?("rspec_local_key")).to be false
      Rails.local_cache.write("rspec_local_key", "exists")
      expect(Rails.local_cache.exist?("rspec_local_key")).to be true
    end
  end

  describe "Rails.global_cache (Redis)" do
    it "successfully connects to the Redis server backend" do
      expect {
        Kredis.redis.ping
      }.not_to raise_error
    end

    it "reads and writes string values" do
      Rails.global_cache.write("rspec_global_key", "hello global")
      expect(Rails.global_cache.read("rspec_global_key")).to eq("hello global")
    end

    it "deletes values" do
      Rails.global_cache.write("rspec_global_key", "to delete")
      Rails.global_cache.delete("rspec_global_key")
      expect(Rails.global_cache.read("rspec_global_key")).to be_nil
    end

    it "fetches and caches a block result" do
      result = Rails.global_cache.fetch("rspec_global_fetch_key", expires_in: 60) { "global computed" }
      expect(result).to eq("global computed")

      cached = Rails.global_cache.read("rspec_global_fetch_key")
      expect(cached).to eq("global computed")
    end

    it "checks key existence" do
      expect(Rails.global_cache.exist?("rspec_global_key")).to be false
      Rails.global_cache.write("rspec_global_key", "exists")
      expect(Rails.global_cache.exist?("rspec_global_key")).to be true
    end
  end

  describe "store independence" do
    it "stores the same key independently in local and global caches" do
      Rails.local_cache.write("rspec_independent_key", "local value")
      Rails.global_cache.write("rspec_independent_key", "global value")

      expect(Rails.local_cache.read("rspec_independent_key")).to eq("local value")
      expect(Rails.global_cache.read("rspec_independent_key")).to eq("global value")
    end
  end
end
