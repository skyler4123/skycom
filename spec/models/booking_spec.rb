# spec/models/booking_spec.rb
require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:booking_resource) }
    it { should belong_to(:price) }
  end
end
