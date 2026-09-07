# frozen_string_literal: true

require "rails_helper"

RSpec.describe Branches::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "branches" }
    let(:index_class) { Branch }
    let(:record) { ->(company:, category:, **attrs) { create(:branch, company: company, category: category, discarded_at: nil, **attrs) } }
  end
end
