require "rails_helper"

RSpec.describe NotificationConfig, type: :model do
  let(:company) { create(:company) }
  let(:employee) { create(:employee, company: company, business_type: :full_time) }

  it "finds or creates one row per employee" do
    config = NotificationConfig.for_employee!(employee)
    expect(config).to be_persisted
    expect(NotificationConfig.for_employee!(employee).id).to eq(config.id)
  end

  it "rejects a second row for the same employee" do
    NotificationConfig.for_employee!(employee)
    expect(NotificationConfig.new(company: company, employee: employee)).not_to be_valid
  end
end
