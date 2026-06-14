# spec/models/page_spec.rb
require "rails_helper"

RSpec.describe Page, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch) }
  end

  describe "enums" do
    it { should define_enum_for(:business_type).with_values(
      retail: 10, restaurant: 20, hospital: 30, education: 40
    ).with_prefix(:business_type) }

    it { should define_enum_for(:target_role).with_values(
      retail_cashier: 110, retail_store_manager: 120,
      restaurant_cashier: 210, restaurant_waiter: 220, restaurant_kitchen_staff: 230,
      hospital_receptionist: 310, hospital_doctor: 320, hospital_nurse: 330
    ) }

    it { should define_enum_for(:target_resolution).with_values(
      mobile_portrait: 10, tablet_landscape: 20, desktop_widescreen: 30
    ).with_prefix(:target_resolution) }

    it { should define_enum_for(:lifecycle_status).with_values(
      active: 10, draft: 20, archived: 30
    ).with_prefix(:lifecycle_status) }

    it { should define_enum_for(:workflow_status).with_values(
      pending_review: 10, approved: 20, deployed: 30
    ).with_prefix(:workflow_status) }
  end
end
