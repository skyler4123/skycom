# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "customers" }
    let(:index_class) { Customer }
    let(:record) { ->(company:, category:, **attrs) { create(:customer, company: company, category: category, **attrs) } }
  end
end
