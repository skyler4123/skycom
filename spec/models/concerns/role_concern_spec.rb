# spec/models/concerns/role_concern_spec.rb
require 'rails_helper'

RSpec.describe RoleConcern do
  describe "when included in an ActiveRecord model" do
    it "adds role_appointments association to Employee" do
      expect(Employee.reflect_on_association(:role_appointments)).to be_a(ActiveRecord::Reflection::HasManyReflection)
    end

    it "adds roles association through role_appointments to Employee" do
      expect(Employee.reflect_on_association(:roles)).to be_a(ActiveRecord::Reflection::ThroughReflection)
    end
  end
end
