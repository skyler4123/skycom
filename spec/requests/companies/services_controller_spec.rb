# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::ServicesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "services" }
    let(:index_class) { Service }
    let(:json_key) { "services" }
    let(:base_json_path) { "/companies/#{company.id}/services.json" }
    # Direct create: the :service factory's nested `association :branch, company: company`
    # rejects a company: override (FactoryBot treats it as an association attribute).
    let(:record) { ->(company:, category:, **attrs) { Service.create!(company: company, category: category, business_type: :b2c, **attrs) } }
  end
end
