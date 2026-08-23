# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::ApplicationController", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  before do
    get sign_in_for_test_path(email: owner_user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "access" do
    it "allows access when lifecycle_status is active" do
      get "/companies/#{company.id}/dashboards"
      expect(response).to have_http_status(:ok)
    end
  end
end
