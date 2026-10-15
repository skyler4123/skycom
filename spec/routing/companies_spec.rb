# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies routes", type: :routing do
  let(:id) { "01a11c12-73a8-7768-bfa0-bee15b5ee278" }
  let(:company_id) { "01a11c12-7229-76d1-85ae-2f45037df89c" }

  it "routes top-level show/edit/update only (no index, no destroy)" do
    expect(get: "/companies/#{id}").to be_routable
    expect(get: "/companies/#{id}/edit").to be_routable
    expect(patch: "/companies/#{id}").to be_routable
  end

  it "does not route top-level index/destroy" do
    expect(get: "/companies").not_to be_routable
    expect(delete: "/companies/#{id}").not_to be_routable
  end

  it "does not route the nested double-/companies path" do
    expect(get: "/companies/#{company_id}/companies/#{id}/edit").not_to be_routable
    expect(patch: "/companies/#{company_id}/companies/#{id}").not_to be_routable
  end
end
