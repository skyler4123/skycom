# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar::AdapterFactory, type: :service do
  let(:company) { create(:company) }

  it "has no registered adapters in v1" do
    expect(described_class.registered_providers).to eq([])
  end

  it "reports every supported provider as unavailable" do
    CALENDAR_SYNC_PROVIDERS.each do |provider|
      expect(described_class.available?(provider)).to be(false)
    end
  end

  it "raises for a provider nobody registered" do
    expect {
      described_class.for(company, provider: "calcom")
    }.to raise_error(described_class::UnknownProvider, /calcom/)
  end

  it "accepts a string or a symbol provider" do
    expect(described_class.available?("calcom")).to be(false)
    expect(described_class.available?(:calcom)).to be(false)
  end

  describe "Calendar::Adapter" do
    it "requires a provider key" do
      expect { Calendar::Adapter.new(company).provider }
        .to raise_error(Calendar::Adapter::NotImplementedError, /#provider/)
    end

    it "raises NotImplementedError on every seam method" do
      adapter = Calendar::Adapter.new(company)
      event = build(:calendar_event, company: company)

      expect { adapter.sync_resource(:anything) }.to raise_error(Calendar::Adapter::NotImplementedError)
      expect { adapter.create_event(event) }.to raise_error(Calendar::Adapter::NotImplementedError)
      expect { adapter.update_event(event) }.to raise_error(Calendar::Adapter::NotImplementedError)
      expect { adapter.cancel_event(event) }.to raise_error(Calendar::Adapter::NotImplementedError)
      expect { adapter.fetch_events(from: 1.day.ago, to: 1.day.from_now) }
        .to raise_error(Calendar::Adapter::NotImplementedError)
      expect { adapter.available_slots(calendar_procedure: nil, from: nil, to: nil) }
        .to raise_error(Calendar::Adapter::NotImplementedError)
    end

    it "exposes the company it was built for" do
      expect(Calendar::Adapter.new(company).company).to eq(company)
    end
  end
end
