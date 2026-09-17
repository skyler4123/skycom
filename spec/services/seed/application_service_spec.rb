# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::ApplicationService do
  describe ".clear_external_services!" do
    before do
      allow(described_class).to receive(:clear_meilisearch!)
      allow(described_class).to receive(:clear_chatwoot!)
    end

    it "clears Meilisearch and Chatwoot before seeding" do
      described_class.clear_external_services!

      expect(described_class).to have_received(:clear_meilisearch!)
      expect(described_class).to have_received(:clear_chatwoot!)
    end
  end

  describe ".clear_chatwoot!" do
    it "delegates to Chatwoot::BaseService.clear_all!" do
      expect(Chatwoot::BaseService).to receive(:clear_all!).and_return(3)

      expect(described_class.clear_chatwoot!).to eq(3)
    end

    it "logs and continues when Chatwoot is unreachable" do
      allow(Chatwoot::BaseService).to receive(:clear_all!).and_raise(Chatwoot::ConnectionError, "refused")
      allow(Rails.logger).to receive(:warn)

      expect { described_class.clear_chatwoot! }.not_to raise_error
      expect(Rails.logger).to have_received(:warn).with(/Chatwoot/)
    end
  end
end
