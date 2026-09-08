# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::TableConfigService do
  describe ".field_hash" do
    it "enables keyword search on string-capable columns" do
      expect(described_class.field_hash("name")).to include("search" => true)
      expect(described_class.field_hash("code", "Invoice No.")).to include("name" => "Invoice No.", "search" => true)
      expect(described_class.field_hash("property_string_1")).to include("search" => true)
    end

    it "enables an active range filter on integer columns" do
      col = described_class.field_hash("property_integer_2")
      expect(col["filter"]).to eq("type" => "range", "active" => true, "buckets" => [ [ nil, 100 ], [ 100, nil ] ])
    end

    it "enables an active range filter with decimal buckets on decimal columns" do
      col = described_class.field_hash("property_decimal_1")
      expect(col["filter"]).to eq("type" => "range", "active" => true, "buckets" => [ [ nil, 10.0 ], [ 10.0, nil ] ])
    end

    it "enables an active boolean filter" do
      col = described_class.field_hash("property_boolean_1")
      expect(col["filter"]).to eq("type" => "boolean", "active" => true, "true_false" => true, "yes_no" => false)
    end

    it "enables an active date filter with year buckets around the current year" do
      year = Time.current.year
      col = described_class.field_hash("property_datetime_1")
      expect(col["filter"]).to eq("type" => "date", "active" => true,
        "buckets" => [ [ nil, year - 1 ], [ year - 1, year ], [ year, nil ] ])
    end

    it "leaves non-string standard columns untouched" do
      col = described_class.field_hash("workflow_status")
      expect(col).not_to have_key("search")
      expect(col).not_to have_key("filter")
    end

    it "produces hashes that pass the model's column validation" do
      keys = %w[name description code business_type workflow_status category_id] +
        %w[property_string_1 property_integer_1 property_decimal_1 property_boolean_1 property_datetime_1]
      company = create(:company)
      category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "products")
      category.default_property_mapping.table_configs.destroy_all

      config = TableConfig.create!(company: company, category: category,
        property_mapping: category.default_property_mapping, resource_name: "products",
        metadata: { "columns" => keys.map { |k| described_class.field_hash(k) } })
      expect(config).to be_valid
      expect(config.columns.count { |c| c["search"] == true }).to eq(4)
      expect(config.columns.count { |c| c["filter"].present? }).to eq(4)
    end
  end
end
