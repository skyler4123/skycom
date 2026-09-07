# frozen_string_literal: true

require "rails_helper"

RSpec.describe Employees::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "employees" }
    let(:index_class) { Employee }
    let(:record) { ->(company:, category:, **attrs) { create(:employee, company: company, category: category, **attrs) } }
  end
end
