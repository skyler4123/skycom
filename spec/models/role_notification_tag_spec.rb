require "rails_helper"

RSpec.describe Role, type: :model do
  let(:company) { create(:company) }

  describe "paired notification tag lifecycle" do
    it "creates a system tag on role create" do
      role = Seed::RoleService.create(company: company, name: "SellerX#{SecureRandom.hex(3)}")
      tag = NotificationTag.find_by(company: company, name: "All #{role.name}")
      expect(tag).to be_present
      expect(tag.system?).to be(true)
    end

    it "skips tag creation for the owner role" do
      owner_role = company.roles.find_by(name: OWNER_BUSINESS_TYPE)
      expect(owner_role).to be_present
      expect(NotificationTag.find_by(company: company, name: "All #{OWNER_BUSINESS_TYPE}")).to be_nil
    end

    it "renames the paired tag when the role is renamed" do
      role = Seed::RoleService.create(company: company, name: "RenameMe#{SecureRandom.hex(3)}")
      old_name = "All #{role.name}"
      role.update!(name: "Renamed#{SecureRandom.hex(3)}")
      expect(NotificationTag.find_by(company: company, name: old_name)).to be_nil
      renamed = NotificationTag.find_by(company: company, name: "All #{role.name}")
      expect(renamed).to be_present
      expect(renamed.system?).to be(true)
    end

    it "recreates a missing paired tag on rename" do
      role = Seed::RoleService.create(company: company, name: "Missing#{SecureRandom.hex(3)}")
      NotificationTag.find_by(company: company, name: "All #{role.name}")&.delete
      role.update!(name: "Recreated#{SecureRandom.hex(3)}")
      expect(NotificationTag.find_by(company: company, name: "All #{role.name}")).to be_present
    end

    it "destroys the paired tag when the role is destroyed" do
      role = Seed::RoleService.create(company: company, name: "Gone#{SecureRandom.hex(3)}")
      tag_id = NotificationTag.find_by(company: company, name: "All #{role.name}")&.id
      expect(tag_id).to be_present
      role.destroy!
      expect(NotificationTag.exists?(tag_id)).to be(false)
    end

    it "fails to destroy a paired system tag directly" do
      role = Seed::RoleService.create(company: company, name: "Direct#{SecureRandom.hex(3)}")
      tag = NotificationTag.find_by(company: company, name: "All #{role.name}")
      expect { tag.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
