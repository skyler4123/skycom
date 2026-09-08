# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Companies::InvoicesController search/filter", type: :request do
  it_behaves_like "dynamic search index controller" do
    let(:resource_name) { "invoices" }
    let(:index_class) { Invoice }
    let(:json_key) { "invoices" }
    let(:base_json_path) { "/companies/#{company.id}/invoices.json" }
    let(:record) do
      lambda do |company:, category:, **attrs|
        order = create(:order, company: company, customer: create(:customer, company: company))
        create(:invoice, company: company, category: category, order: order, discarded_at: nil, **attrs)
      end
    end
  end
end
