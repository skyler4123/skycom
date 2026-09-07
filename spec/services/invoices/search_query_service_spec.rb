# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoices::SearchQueryService do
  it_behaves_like "dynamic search query service" do
    let(:service_class) { described_class }
    let(:resource_name) { "invoices" }
    let(:index_class) { Invoice }
    let(:record) do
      lambda do |company:, category:, **attrs|
        order = create(:order, company: company, customer: create(:customer, company: company))
        create(:invoice, company: company, category: category, order: order, discarded_at: nil, **attrs)
      end
    end
  end
end
