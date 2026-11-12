# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile sign-in", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  it "renders only the shell" do
    get mobile_sign_in_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="mobile--sessions--new"')
    expect(response.body).to include(
      %(data-json-url="#{mobile_sign_in_path(format: :json)}")
    )
    expect(response.body).not_to include("Welcome back")
  end

  it "returns the empty sign-in payload as JSON" do
    get mobile_sign_in_path(format: :json)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["email"]).to be_nil
  end

  it "re-renders the shell with the error and email on invalid credentials" do
    post mobile_sign_in_path, params: { email: user.email, password: "wrong_password" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('data-controller="mobile--sessions--new"')
    expect(response.body).to include("data-errors")
    expect(response.body).to include("Invalid email or password")
    expect(response.body).to include("data-values")
    expect(response.body).to include(user.email)
  end

  it "redirects to the company home on valid credentials" do
    post mobile_sign_in_path, params: { email: user.email, password: "Password@1234" }

    expect(response).to redirect_to(mobile_company_home_path(company))
  end
end
