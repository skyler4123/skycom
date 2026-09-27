# spec/models/product_product_group_appointment_spec.rb
require "rails_helper"

RSpec.describe ProductProductGroupAppointment, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:product) }
    it { should belong_to(:product_group) }
  end
end
