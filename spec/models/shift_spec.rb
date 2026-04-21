# spec/models/shift_spec.rb
require 'rails_helper'

RSpec.describe Shift, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:branch).optional }
    it { should belong_to(:period) }
  end
end
