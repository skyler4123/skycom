# spec/models/property_mapping_spec.rb
require 'rails_helper'

RSpec.describe PropertyMapping, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category).optional }
  end
end
