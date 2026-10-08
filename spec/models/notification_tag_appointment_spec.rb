require "rails_helper"

RSpec.describe NotificationTagAppointment, type: :model do
  let(:company) { create(:company) }
  let(:notif) { Notification.create!(company: company, title: "t") }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:notification) }
    it { should belong_to(:notification_tag) }
  end

  it "derives company_id on appointment from notification" do
    row = NotificationTagAppointment.new(notification: notif, notification_tag: tag)
    row.valid?
    expect(row.company_id).to eq(company.id)
  end
end
