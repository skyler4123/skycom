# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User::SearchConcern" do
  before(:all) do
    @meili_available = begin
      Meilisearch::Rails.client.health["status"] == "available"
    rescue StandardError
      false
    end
    unless @meili_available
      raise "Meilisearch not reachable at #{Meilisearch::Rails.configuration[:meilisearch_url]}. Run `docker compose up -d meilisearch`."
    end
  end

  before { User.ms_clear_index! }
  after  { User.ms_clear_index! }

  describe "index settings" do
    it "applies searchable + filterable attributes declared by the concern" do
      settings = User.ms_index.settings

      expect(settings["searchableAttributes"])
        .to match_array(%w[email username name first_name last_name phone_number])
      expect(settings["filterableAttributes"])
        .to match_array(%w[system_role country workflow_status business_type])
    end

    it "never indexes sensitive columns" do
      user = create(:user)
      user.ms_index!(true)

      hit = User.ms_raw_search(user.name)["hits"].first
      expect(hit).to be_present
      expect(hit).not_to have_key("password_digest")
      expect(hit).not_to have_key("single_access_token")
    end
  end

  describe "asynchronous indexing" do
    it "routes create/update indexing through MeilisearchIndexJob" do
      user = create(:user)

      allow(MeilisearchIndexJob).to receive(:perform_later)
      user.ms_enqueue_index!(false)

      expect(MeilisearchIndexJob).to have_received(:perform_later).with("User", user.id, false)
    end

    it "routes destroy removal through MeilisearchIndexJob" do
      user = create(:user)

      allow(MeilisearchIndexJob).to receive(:perform_later)
      user.ms_enqueue_remove_from_index!(false)

      expect(MeilisearchIndexJob).to have_received(:perform_later).with("User", user.id, true)
    end

    it "indexes the document when the job runs" do
      user = create(:user, name: "Meili Job Indexed #{SecureRandom.hex(4)}")
      MeilisearchIndexJob.perform_now("User", user.id, false)

      hits = User.ms_raw_search(user.name)["hits"]
      expect(hits.map { |h| h["id"] }).to include(user.id)
    end

    it "removes a destroyed record when the job runs" do
      user = create(:user, name: "Meili Job Removed #{SecureRandom.hex(4)}")
      id = user.id
      MeilisearchIndexJob.perform_now("User", id, false)

      user.destroy!
      MeilisearchIndexJob.perform_now("User", id, true)

      expect(User.ms_raw_search(user.name)["hits"]).to be_empty
    end
  end

  describe "filtering" do
    it "supports filterable scopes on system_role and country" do
      user = create(:user, system_role: :super_admin, name: "Meili Filtered #{SecureRandom.hex(4)}")
      user.ms_index!(true)

      hits = User.ms_raw_search(user.name, filter: "system_role = \"super_admin\"")["hits"]
      expect(hits.map { |h| h["id"] }).to include(user.id)

      other_hits = User.ms_raw_search(user.name, filter: "system_role = \"company_employee\"")["hits"]
      expect(other_hits).to be_empty
    end
  end
end
