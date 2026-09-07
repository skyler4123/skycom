# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "services" }
    let(:index_class) { Service }
    # Direct create: the :service factory's nested `association :branch, company: company`
    # rejects a company: override (FactoryBot treats it as an association attribute).
    let(:record) { ->(company:, category:, **attrs) { Service.create!(company: company, category: category, business_type: :b2c, **attrs) } }
  end
end
