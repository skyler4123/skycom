# frozen_string_literal: true

require "rails_helper"

RSpec.describe ComputedColumns, type: :service do
  describe ".for" do
    it "returns the computed catalog for a model that declares one" do
      expect(described_class.for("products")).to include(
        "key" => "quantity", "name" => "Quantity", "type" => "integer"
      )
    end

    it "returns nil for a model that does not include the concern" do
      expect(described_class.for("stocks")).to be_nil
    end

    it "returns nil for an unknown resource name" do
      expect(described_class.for("not_a_real_resource")).to be_nil
    end
  end

  describe ".model_for" do
    it "resolves a plural resource name to its ApplicationRecord model" do
      expect(described_class.model_for("products")).to eq(Product)
    end

    it "does not resolve arbitrary non-model constants" do
      expect(described_class.model_for("string")).to be_nil
    end
  end

  describe "real column precedence" do
    it "never declares a computed key that is already a real DB column" do
      ApplicationRecord.descendants.each do |model|
        next unless model.respond_to?(:computed_columns)

        overlap = model.computed_columns.map { |column| column["key"] } & model.column_names
        expect(overlap).to be_empty, "#{model.name} declares a computed key that is a real DB column: #{overlap.join(', ')}"
      end
    end
  end
end
