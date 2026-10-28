# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile::Companies::NotificationsController", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }
  let!(:employee) { company.employees.find_by(user: user) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  before { get sign_in_for_test_path(email: user.email) }

  it "renders notifications for the employee" do
    get mobile_company_notifications_path(company)
    expect(response).to have_http_status(:ok)
  end

  it "returns not found when the user has no employee record" do
    stranger = create(:user)
    get sign_in_for_test_path(email: stranger.email)
    get mobile_company_notifications_path(company)
    expect(response).to have_http_status(:not_found)
  end

  it "does not serve notifications for another company" do
    other_company = create(:company)
    get mobile_company_notifications_path(other_company)
    expect(response).to have_http_status(:not_found)
  end
end