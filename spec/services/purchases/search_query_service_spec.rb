# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "purchases" }
    let(:index_class) { Purchase }
    let(:record) { ->(company:, category:, **attrs) { create(:purchase, company: company, category: category, **attrs) } }
  end
end
