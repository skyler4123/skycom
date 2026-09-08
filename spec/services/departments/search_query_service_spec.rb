# frozen_string_literal: true

require "rails_helper"

RSpec.describe Departments::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "departments" }
    let(:index_class) { Department }
    let(:record) { ->(company:, category:, **attrs) { create(:department, company: company, category: category, **attrs) } }
  end
end
