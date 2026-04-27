# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:sessions).dependent(:destroy) }
    it { should have_many(:sign_in_tokens).dependent(:destroy) }
    it { should have_many(:companies).dependent(:destroy) }
    it { should have_many(:employees).dependent(:destroy) }
    it { should have_many(:customers).dependent(:destroy) }
    it { should belong_to(:parent_user).class_name("User").optional }
    it { should have_many(:child_users).class_name("User").with_foreign_key("parent_user_id").dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
describe "name uniqueness" do
      let!(:user) { create(:user, name: "Skycom User") }

      it "validates uniqueness when present" do
        new_user = build(:user, name: "Skycom User")
        expect(new_user).not_to be_valid
        expect(new_user.errors[:name]).to include("has already been taken")
      end

      it "allows multiple users with blank names" do
        create(:user, name: "")
        expect { create(:user, name: "") }.not_to raise_error
        
        create(:user, name: nil)
        expect { create(:user, name: nil) }.not_to raise_error
      end
    end
  end

  describe "enums" do
    it { should define_enum_for(:system_role).with_values(super_admin: 0, admin: 1, company_owner: 2, company_employee: 3, company_customer: 4).with_prefix(:system_role) }
    it { should define_enum_for(:country_code) }
  end

  describe "#company_owner" do
    it "returns self when parent_user is nil" do
      user = build_stubbed(:user, parent_user: nil)
      expect(user.company_owner).to eq(user)
    end

    it "returns parent_user when parent_user is present" do
      parent = build_stubbed(:user)
      user = build_stubbed(:user, parent_user: parent)
      expect(user.company_owner).to eq(parent)
    end
  end

  describe "#employee_users" do
    it "is an alias for child_users" do
      user = build_stubbed(:user)
      expect(user.employee_users).to eq(user.child_users)
    end
  end
end
