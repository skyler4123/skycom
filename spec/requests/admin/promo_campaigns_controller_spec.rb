require "rails_helper"

RSpec.describe "Admin::PromoCampaigns", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:company_owner_user) { create(:user, :company_owner) }
  let!(:campaign) { create(:promo_campaign) }

  let(:json_headers) { { "ACCEPT" => "application/json" } }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET /admin/promo_campaigns" do
    before { get sign_in_for_test_path(email: admin.email) }

    it "returns campaigns with pagination" do
      get "/admin/promo_campaigns", headers: json_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["promo_campaigns"].map { |c| c["id"] }).to include(campaign.id)
      expect(body["pagination"]).to be_present
    end
  end

  describe "POST /admin/promo_campaigns" do
    before { get sign_in_for_test_path(email: admin.email) }

    it "creates a campaign and enqueues the job" do
      expect {
        post "/admin/promo_campaigns",
          params: { promo_campaign: { name: "Launch Gift", title: "Gift!", body: "Enjoy", amount: 300, max_cap: 1000,
            scheduled_at: 1.hour.from_now.iso8601, conditions: { country: [ "us" ] } } },
          headers: json_headers
      }.to change { PromoCampaign.count }.by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["promo_campaign"]["status"]).to eq("scheduled")
      expect(body["promo_campaign"]["title"]).to eq("Gift!")
      expect(body["promo_campaign"]["body"]).to eq("Enjoy")
      expect(SolidQueue::Job.where(class_name: "PromoCampaignJob").count).to be >= 1
    end

    it "rejects missing title with plural errors" do
      post "/admin/promo_campaigns",
        params: { promo_campaign: { name: "Bad", amount: 300, max_cap: 1000, scheduled_at: Time.current.iso8601 } },
        headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_an(Array)
      expect(PromoCampaign.where(name: "Bad").count).to eq(0)
    end

    it "rejects invalid params with plural errors key" do
      post "/admin/promo_campaigns",
        params: { promo_campaign: { name: "Bad", amount: -5, max_cap: 1000, scheduled_at: Time.current.iso8601 } },
        headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_an(Array)
    end
  end

  describe "POST /admin/promo_campaigns/:id/run_now" do
    before { get sign_in_for_test_path(email: admin.email) }

    it "runs a draft campaign" do
      draft = create(:promo_campaign, status: :draft)

      post "/admin/promo_campaigns/#{draft.id}/run_now", headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(draft.reload).to be_status_completed
    end

    it "rejects an already completed campaign" do
      done = create(:promo_campaign, status: :completed, processed_at: Time.current)

      post "/admin/promo_campaigns/#{done.id}/run_now", headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_an(Array)
    end
  end

  describe "POST /admin/promo_campaigns/:id/cancel" do
    before { get sign_in_for_test_path(email: admin.email) }

    it "cancels a scheduled campaign" do
      post "/admin/promo_campaigns/#{campaign.id}/cancel", headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(campaign.reload).to be_status_failed
    end

    it "rejects cancel on a completed campaign" do
      done = create(:promo_campaign, status: :completed, processed_at: Time.current)

      post "/admin/promo_campaigns/#{done.id}/cancel", headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_an(Array)
    end
  end

  describe "PATCH /admin/promo_campaigns/:id" do
    before { get sign_in_for_test_path(email: admin.email) }

    it "rejects update on a completed campaign" do
      done = create(:promo_campaign, status: :completed, processed_at: Time.current)

      patch "/admin/promo_campaigns/#{done.id}",
        params: { promo_campaign: { name: "Renamed" } }, headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_an(Array)
    end

    it "rejects unknown condition keys" do
      post "/admin/promo_campaigns",
        params: { promo_campaign: { name: "Bad", amount: 300, max_cap: 1000,
          scheduled_at: Time.current.iso8601, conditions: { foo: "1" } } },
        headers: json_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_an(Array)
    end
  end

  describe "non-admin access" do
    before { get sign_in_for_test_path(email: company_owner_user.email) }

    it "redirects to root" do
      get "/admin/promo_campaigns"

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(root_path)
    end
  end
end
