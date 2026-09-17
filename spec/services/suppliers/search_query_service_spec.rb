# frozen_string_literal: true

require "rails_helper"

RSpec.describe Suppliers::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "suppliers" }
    let(:index_class) { Supplier }
    let(:record) { ->(company:, category:, **attrs) { create(:supplier, company: company, category: category, **attrs) } }
  end
end
