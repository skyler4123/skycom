# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportLog, type: :model do
  let!(:company) { create(:company) }

  describe "associations" do
    it { should belong_to(:import) }
    it { should belong_to(:company) }
    it { should belong_to(:record) }
  end

  describe "validations" do
    it { should validate_presence_of(:action) }
    it { should validate_presence_of(:record_type) }
    it { should validate_presence_of(:record_id) }
  end

  describe "action" do
    it "maps the create-only audit action" do
      expect(described_class.actions).to eq("created" => 0)
    end
  end

  it "enforces one log per record per import" do
    import = create(:import, company: company)
    product = create(:product, company: company)
    create(:import_log, import: import, company: company, record: product)

    duplicate = build(:import_log, import: import, company: company, record: product)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
