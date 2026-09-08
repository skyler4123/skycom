# frozen_string_literal: true

require "rails_helper"

RSpec.describe Brands::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "brands" }
    let(:index_class) { Brand }
    let(:record) { ->(company:, category:, **attrs) { create(:brand, company: company, category: category, **attrs) } }
  end
end
