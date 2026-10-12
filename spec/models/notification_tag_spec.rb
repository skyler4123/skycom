require "rails_helper"

RSpec.describe NotificationTag, type: :model do
  let(:company) { create(:company) }

  it "requires name unique per company" do
    NotificationTag.create!(company: company, name: "ops")
    expect(NotificationTag.new(company: company, name: "ops")).not_to be_valid
  end

  it "marks system tags with business_type system" do
    tag = NotificationTag.create!(company: company, name: "All Company", business_type: :system)
    expect(tag.system?).to be(true)
  end

  it "prevents deletion of system tags" do
    tag = NotificationTag.create!(company: company, name: "All Company", business_type: :system)
    expect { tag.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord, "System notification tags cannot be deleted.")
  end

  it "allows deletion of custom tags" do
    tag = NotificationTag.create!(company: company, name: "my-tag", business_type: :custom)
    expect { tag.destroy! }.not_to raise_error
    expect(NotificationTag.exists?(tag.id)).to be(false)
  end
end
