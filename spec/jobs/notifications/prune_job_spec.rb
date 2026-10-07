require "rails_helper"

RSpec.describe Notifications::PruneJob, type: :job do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }

  it "prunes notifications older than retention" do
    old = Notifications::CreateService.call(company: company, title: "old", tag_ids: [ tag.id ])[:notification]
    old.update_column(:created_at, 100.days.ago)
    fresh = Notifications::CreateService.call(company: company, title: "fresh", tag_ids: [ tag.id ])[:notification]

    described_class.perform_now

    expect(Notification.exists?(old.id)).to be(false)
    expect(Notification.exists?(fresh.id)).to be(true)
  end
end
