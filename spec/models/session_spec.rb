# spec/models/session_spec.rb
require "rails_helper"

RSpec.describe Session, type: :model do
  describe "cache keys" do
    it "writes the session under the service key" do
      session = Session.create!(user: create(:user))

      session.send(:refresh_cache)

      expect(Rails.sync_cache.read(CacheKeyService.session(session.id)))
        .to include("user_id" => session.user_id)
    end

    it "removes the session key" do
      session = Session.create!(user: create(:user))
      key = CacheKeyService.session(session.id)
      Rails.sync_cache.write(key, { "id" => session.id })

      session.send(:remove_cache)

      expect(Rails.sync_cache.read(key)).to be_nil
    end
  end
end
