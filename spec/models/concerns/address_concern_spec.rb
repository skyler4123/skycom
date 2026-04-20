# spec/models/concerns/address_concern_spec.rb
require 'rails_helper'

RSpec.describe AddressConcern do
  describe "when included in an ActiveRecord model" do
    it "adds address_appointment association to Branch" do
      expect(Branch.reflect_on_association(:address_appointment)).to be_a(ActiveRecord::Reflection::HasOneReflection)
    end

    it "adds address association through address_appointment to Branch" do
      expect(Branch.reflect_on_association(:address)).to be_a(ActiveRecord::Reflection::ThroughReflection)
    end
  end
end
