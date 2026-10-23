# spec/system/sync_cache_spec.rb
require "rails_helper"

RSpec.describe "Rails.sync_cache & RecordsConcern Integration", type: :model do
  let(:user) { User.create!(email: "test_#{SecureRandom.hex(4)}@example.com", password: "password12345") }
  let(:cache_key) { "users_#{user.id}" }

  after do
    Rails.sync_cache.delete(cache_key, sync: false)
  end

  describe "Rails.sync_cache" do
    it "writes and reads from local_cache" do
      Rails.sync_cache.write(cache_key, { "id" => user.id, "email" => user.email })
      expect(Rails.sync_cache.read(cache_key)).to include("email" => user.email)
    end

    it "publishes invalidation on delete" do
      expect(Rails.sync_cache).to receive(:publish_invalidation).with("delete", cache_key).and_call_original
      Rails.sync_cache.delete(cache_key)
    end

    it "handles incoming invalidation payloads cleanly" do
      Rails.sync_cache.write(cache_key, { "id" => user.id }, sync: false)
      expect(Rails.sync_cache.read(cache_key)).not_to be_nil

      payload = { action: "delete", key: cache_key }.to_json
      Rails.sync_cache.handle_invalidation(payload)

      expect(Rails.sync_cache.read(cache_key)).to be_nil
    end
  end

  # Cache::RecordsConcern (cached_find/cached_where) removed; records are
  # loaded via normal DB queries. Rails.sync_cache basic behavior remains
  # covered above.
end
