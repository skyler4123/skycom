# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "events" }
    let(:index_class) { Event }
    let(:record) { ->(company:, category:, **attrs) { create(:event, company: company, category: category, **attrs) } }
  end
end
