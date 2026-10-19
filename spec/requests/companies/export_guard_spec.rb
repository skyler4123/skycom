require "rails_helper"

RSpec.describe "Companies Export Guard", type: :request do
  let(:company) { create(:company) }
  let(:owner_user) { company.user }

  before { get sign_in_for_test_path(email: owner_user.email) }

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  it "allows export on an enabled resource" do
    get company_products_path(company, format: :json), params: { export: "1" }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body).to have_key("products")
  end

  it "rejects export on a disabled resource" do
    get company_tax_path(company, format: :json), params: { export: "1" }
    expect(response).to have_http_status(:unprocessable_content)
    body = JSON.parse(response.body)
    expect(body["errors"]).to include("Export is not enabled for this page")
  end
end
