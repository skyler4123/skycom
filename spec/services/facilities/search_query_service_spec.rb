# frozen_string_literal: true

require "rails_helper"

RSpec.describe Facilities::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "facilities" }
    let(:index_class) { Facility }
    let(:record) { ->(company:, category:, **attrs) { create(:facility, company: company, category: category, **attrs) } }
  end
end
