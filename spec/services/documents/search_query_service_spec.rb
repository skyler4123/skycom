# frozen_string_literal: true

require "rails_helper"

RSpec.describe Documents::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "documents" }
    let(:index_class) { Document }
    let(:record) { ->(company:, category:, **attrs) { Seed::DocumentService.create(company: company, category: category, **attrs) } }
  end
end
