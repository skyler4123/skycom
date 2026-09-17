# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chatwoot::BaseService do
  let(:company) { create(:company) }

  before do
    allow(Chatwoot::Client).to receive(:platform_token).and_return("platform_token")
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe ".create_account!" do
    subject(:result) { described_class.create_account!(company: company) }

    let(:account_response) { { "id" => 42, "name" => company.name } }

    context "when the company has no chatwoot account yet" do
      before do
        allow(Chatwoot::Client).to receive(:post)
          .with("accounts", body: hash_including("name" => company.name))
          .and_return(account_response)
      end

      it "creates the account and stores the chatwoot account id" do
        expect { result }.to change { company.reload.chatwoot_account_id }.from(nil).to(42)
        expect(result).to eq(account_response)
      end

      it "stamps the skycom company id as a custom attribute" do
        described_class.create_account!(company: company)

        expect(Chatwoot::Client).to have_received(:post).with(
          "accounts",
          body: hash_including("custom_attributes" => { "skycom_company_id" => company.id })
        )
      end
    end

    context "when the company already has a reachable chatwoot account" do
      before do
        company.update!(chatwoot_account_id: 42)
        allow(Chatwoot::Client).to receive(:get).with("accounts/42").and_return(account_response)
      end

      it "returns the existing account without creating a new one" do
        expect(Chatwoot::Client).not_to receive(:post)

        expect(result).to eq(account_response)
      end
    end

    context "when the stored account id is no longer reachable" do
      before do
        company.update!(chatwoot_account_id: 42)
        allow(Chatwoot::Client).to receive(:get).with("accounts/42").and_raise(Chatwoot::NotFoundError, "not found")
        allow(Chatwoot::Client).to receive(:post)
          .with("accounts", body: hash_including("name" => company.name))
          .and_return(account_response)
      end

      it "re-provisions a new account" do
        expect(result).to eq(account_response)
        expect(company.reload.chatwoot_account_id).to eq(42)
      end
    end

    context "when the platform token is missing" do
      before { allow(Chatwoot::Client).to receive(:platform_token).and_return(nil) }

      it "warns and performs no HTTP request" do
        expect(Chatwoot::Client).not_to receive(:get)
        expect(Chatwoot::Client).not_to receive(:post)

        expect(result).to be_nil
        expect(Rails.logger).to have_received(:warn).with(/CHATWOOT_PLATFORM_TOKEN/).at_least(:once)
        expect(company.reload.chatwoot_account_id).to be_nil
      end
    end

    context "when the platform API rejects the account creation" do
      before { allow(Chatwoot::Client).to receive(:post).and_raise(Chatwoot::Error, "Validation failed") }

      it "raises the error" do
        expect { result }.to raise_error(Chatwoot::Error)
        expect(company.reload.chatwoot_account_id).to be_nil
      end
    end
  end

  describe ".account_for" do
    subject(:result) { described_class.account_for(company) }

    context "when the company has no stored chatwoot account id" do
      it "returns nil without any HTTP request" do
        expect(Chatwoot::Client).not_to receive(:get)

        expect(result).to be_nil
      end
    end

    context "when the stored chatwoot account is reachable" do
      before do
        company.update!(chatwoot_account_id: 42)
        allow(Chatwoot::Client).to receive(:get).with("accounts/42").and_return({ "id" => 42, "name" => company.name })
      end

      it "returns the account payload" do
        expect(result).to eq({ "id" => 42, "name" => company.name })
      end
    end

    context "when the stored chatwoot account is gone" do
      before do
        company.update!(chatwoot_account_id: 42)
        allow(Chatwoot::Client).to receive(:get).with("accounts/42").and_raise(Chatwoot::NotFoundError, "not found")
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when Chatwoot is unreachable" do
      before do
        company.update!(chatwoot_account_id: 42)
        allow(Chatwoot::Client).to receive(:get).with("accounts/42").and_raise(Chatwoot::ConnectionError, "refused")
      end

      it "raises the transport error" do
        expect { result }.to raise_error(Chatwoot::ConnectionError)
      end
    end

    context "when the platform token is missing" do
      before { allow(Chatwoot::Client).to receive(:platform_token).and_return(nil) }

      it "raises a configuration error" do
        expect { result }.to raise_error(Chatwoot::Error, /not configured/)
      end
    end
  end

  describe ".clear_all!" do
    subject(:result) { described_class.clear_all! }

    before { stub_const("Chatwoot::BaseService::CLEAR_MISS_LIMIT", 3) }

    context "when accounts exist consecutively" do
      before do
        allow(Chatwoot::Client).to receive(:get).and_raise(Chatwoot::NotFoundError, "not found")
        allow(Chatwoot::Client).to receive(:get).with("accounts/1").and_return({ "id" => 1 })
        allow(Chatwoot::Client).to receive(:get).with("accounts/2").and_return({ "id" => 2 })
        allow(Chatwoot::Client).to receive(:delete).with("accounts/1")
        allow(Chatwoot::Client).to receive(:delete).with("accounts/2")
      end

      it "deletes every reachable account" do
        expect(Chatwoot::Client).to receive(:delete).with("accounts/1")
        expect(Chatwoot::Client).to receive(:delete).with("accounts/2")

        expect(result).to eq(2)
      end
    end

    context "when ids have gaps from previous reseeds" do
      before do
        allow(Chatwoot::Client).to receive(:get).and_raise(Chatwoot::NotFoundError, "not found")
        allow(Chatwoot::Client).to receive(:get).with("accounts/2").and_return({ "id" => 2 })
        allow(Chatwoot::Client).to receive(:delete).with("accounts/2")
      end

      it "keeps scanning until the consecutive miss limit and resets on success" do
        expect(result).to eq(1)
      end
    end

    context "when a reachable account cannot be deleted" do
      before do
        allow(Chatwoot::Client).to receive(:get).with("accounts/1").and_return({ "id" => 1 })
        allow(Chatwoot::Client).to receive(:delete).with("accounts/1")
          .and_raise(Chatwoot::UnauthorizedError, "denied")
      end

      it "raises the error" do
        expect { result }.to raise_error(Chatwoot::UnauthorizedError)
      end
    end

    context "when the platform token is missing" do
      before { allow(Chatwoot::Client).to receive(:platform_token).and_return(nil) }

      it "warns and performs no HTTP request" do
        expect(Chatwoot::Client).not_to receive(:get)

        expect(result).to eq(0)
        expect(Rails.logger).to have_received(:warn).with(/CHATWOOT_PLATFORM_TOKEN/)
      end
    end
  end
end
