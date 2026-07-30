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

  describe "Cache::RecordsConcern integration" do
    it "caches record attributes on cached_find" do
      cached_user = User.cached_find(user.id)
      expect(cached_user.id).to eq(user.id)

      expect(Rails.sync_cache.read(cache_key)).not_to be_nil
    end

    it "automatically updates cache after_commit on update" do
      User.cached_find(user.id) # warm cache
      user.update!(email: "updated_#{SecureRandom.hex(4)}@example.com")

      cached_data = Rails.sync_cache.read(cache_key)
      expect(cached_data["email"]).to eq(user.email)
    end

    it "evicts cache after_commit on destroy" do
      User.cached_find(user.id) # warm cache
      session = user.sessions.create!

      session.destroy # triggers after_commit :remove_attribute_cache

      expect(Rails.sync_cache.read("sessions_#{session.id}")).to be_nil
    end
  end
end