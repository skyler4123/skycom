# spec/models/concerns/immutable_record_concern_spec.rb
require 'rails_helper'

RSpec.describe ImmutableRecordConcern do
  describe "module exists" do
    it "is defined" do
      expect(defined?(ImmutableRecordConcern)).to be_truthy
    end

    it "responds to included" do
      expect(ImmutableRecordConcern).to respond_to(:included)
    end
  end
end
