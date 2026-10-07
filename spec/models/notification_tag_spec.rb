require "rails_helper"

RSpec.describe NotificationTag, type: :model do
  let(:company) { create(:company) }

  it "requires name unique per company" do
    NotificationTag.create!(company: company, name: "ops")
    expect(NotificationTag.new(company: company, name: "ops")).not_to be_valid
  end
end
