# spec/models/concerns/tag_concern_spec.rb
require 'rails_helper'

RSpec.describe TagConcern do
  describe "when included in an ActiveRecord model" do
    it "adds tag_appointments association to Branch" do
      expect(Branch.reflect_on_association(:tag_appointments)).to be_a(ActiveRecord::Reflection::HasManyReflection)
    end

    it "adds tags association through tag_appointments to Branch" do
      expect(Branch.reflect_on_association(:tags)).to be_a(ActiveRecord::Reflection::ThroughReflection)
    end
  end
end
