# frozen_string_literal: true

require "rails_helper"

RSpec.describe Booking::CustomerSearchService do
  let(:company) { create(:company) }
  let(:customer) { create(:customer, company: company, name: "Vanguard Capital", code: "CUS-1", email: "ops@vanguard.test") }

  it "returns nothing for a blank query without calling Meilisearch" do
    expect(Customer).not_to receive(:ms_raw_search)

    expect(described_class.call(company: company, query: "  ")).to eq([])
  end

  it "maps Meilisearch hits to the customer summary" do
    allow(Customer).to receive(:ms_raw_search).and_return("hits" => [ { "id" => customer.id } ])

    result = described_class.call(company: company, query: "Vanguard")

    expect(result).to eq([
      { id: customer.id, name: "Vanguard Capital", code: "CUS-1", email: "ops@vanguard.test" }
    ])
    expect(Customer).to have_received(:ms_raw_search).with(
      "Vanguard", filter: %(company_id = "#{company.id}"), limit: 10
    )
  end

  it "propagates Meilisearch failures" do
    allow(Customer).to receive(:ms_raw_search).and_raise(Meilisearch::CommunicationError.new("down"))

    expect { described_class.call(company: company, query: "Vanguard") }
      .to raise_error(Meilisearch::CommunicationError)
  end
end
