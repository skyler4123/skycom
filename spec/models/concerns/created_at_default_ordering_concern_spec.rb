# spec/models/concerns/created_at_default_ordering_concern_spec.rb
require 'rails_helper'

RSpec.describe CreatedAtDefaultOrderingConcern do
  describe "implicit_order_column" do
    let(:test_class) do
      Class.new(Brand) do
        include CreatedAtDefaultOrderingConcern
        def self.name
          "TestOrderable"
        end
      end
    end

    it "sets implicit_order_column to created_at" do
      expect(test_class.implicit_order_column).to eq("created_at")
    end
  end
end
