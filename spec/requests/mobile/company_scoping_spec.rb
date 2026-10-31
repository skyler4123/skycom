# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile company scoping", type: :request do
  let(:company) { create(:company) }
  let(:user) { company.user }

  before { get sign_in_for_test_path(email: user.email) }

  it "renders the company home for a member" do
    get mobile_company_home_path(company)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(company.name)
  end

  it "returns not found for another company" do
    other_company = create(:company)

    get mobile_company_home_path(other_company)

    expect(response).to have_http_status(:not_found)
  end

  it "returns not found for another company's operations" do
    other_company = create(:company)

    get mobile_company_operations_path(other_company)

    expect(response).to have_http_status(:not_found)
  end

  it "returns not found when the user has no employee record" do
    stranger = create(:user)
    get sign_in_for_test_path(email: stranger.email)

    get mobile_company_home_path(company)

    expect(response).to have_http_status(:not_found)
  end

  it "rejects malformed company ids at the routing layer" do
    get "/mobile/companies/not-a-company/home"

    expect(response).to have_http_status(:not_found)
  end
end
