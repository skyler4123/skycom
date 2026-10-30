# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::AnnouncementService do
  let(:company) { create(:company) }
  let!(:employee) { company.employees.find_by(business_type: :owner) }

  it "creates one published announcement linked to every employee" do
    described_class.create_samples!(company: company)

    document = company.documents.announcements.published.find_by!(name: described_class::TITLE)

    expect(document.employees).to include(employee)
  end

  it "is idempotent when run twice" do
    described_class.create_samples!(company: company)

    expect do
      described_class.create_samples!(company: company)
    end.not_to change(Document, :count)
  end
end
