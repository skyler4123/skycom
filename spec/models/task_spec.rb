# spec/models/task_spec.rb
require 'rails_helper'

RSpec.describe Task, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:task_group) }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:business_type) }
    it { should validate_length_of(:name).is_at_most(255) }
  end

  describe "enums" do
    it { should define_enum_for(:lifecycle_status) }
    it { should define_enum_for(:workflow_status) }
    it { should define_enum_for(:business_type).with_values(general: 0, technical: 1, administrative: 2) }
    it { should define_enum_for(:currency_code).with_values(usd: 0, eur: 1, gbp: 2) }
  end
end
