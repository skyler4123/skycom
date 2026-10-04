# spec/models/event_spec.rb
require 'rails_helper'

RSpec.describe Event, type: :model do
  describe "associations" do
    it { should belong_to(:event_group).optional }
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:category) }
    it { should belong_to(:property_mapping) }
    it { should have_many(:event_tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:event_tag_appointments) }
    it { should have_many(:branch_event_appointments).dependent(:destroy) }
    it { should have_many(:customer_event_appointments).dependent(:destroy) }
    it { should have_many(:event_service_appointments).dependent(:destroy) }
    it { should have_many(:event_facility_appointments).dependent(:destroy) }
    it { should have_many(:event_stock_appointments).dependent(:destroy) }
    it { should have_many(:event_order_appointments).dependent(:destroy) }
    it { should have_many(:employee_event_appointments).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "time window" do
    it "is invalid when end_at precedes start_at" do
      event = build(:event, start_at: 3.hours.from_now, end_at: 2.hours.from_now)
      expect(event).not_to be_valid
      expect(event.errors[:end_at]).to be_present
    end

    it "is valid when end_at follows start_at" do
      event = build(:event, start_at: 2.hours.from_now, end_at: 3.hours.from_now)
      expect(event).to be_valid
    end
  end
  it_behaves_like "property_mapping concern", Event
end
