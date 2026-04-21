# spec/models/setting_spec.rb
require 'rails_helper'

RSpec.describe Setting, type: :model do
  describe "associations" do
    it { should belong_to(:setting_group) }
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should have_many(:tag_appointments).dependent(:destroy) }
    it { should have_many(:tags).through(:tag_appointments) }
  end
end
