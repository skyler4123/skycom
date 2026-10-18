# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe CompanyMigrations::RowMapper do
  let!(:company) { create(:company) }

  let(:fixture_rows) { CSV.read(Rails.root.join("faker/files/customers-10.csv"), headers: true) }

  def build_mapper(columns:, defaults: {})
    described_class.new(
      target: {
        "resource" => "customers",
        "identity" => { "column" => "Customer Id" },
        "category" => { "mode" => "create_or_reuse", "name" => "Imported Customers" },
        "columns" => columns,
        "defaults" => defaults
      },
      company: company
    )
  end

  def customer_columns
    {
      "First Name" => { "target" => "name" },
      "Email" => { "target" => "email" },
      "Phone 1" => { "target" => "phone_number" },
      "Company" => { "target" => "property_string_1" },
      "Website" => { "target" => "metadata.website" }
    }
  end

  describe "#map" do
    it "maps the first fixture row to the expected attrs" do
      result = build_mapper(columns: customer_columns).map(fixture_rows[0])

      expect(result[:errors]).to be_empty
      expect(result[:attrs]).to include(
        "name" => "Andrew",
        "email" => "marieyates@gomez-spencer.info",
        "phone_number" => "846-790-4623x4715",
        "property_string_1" => "Stewart-Flynn"
      )
      expect(result[:attrs]["metadata"]).to eq("website" => "http://www.shea.biz/")
    end

    it "ignores unmapped columns" do
      result = build_mapper(columns: { "First Name" => { "target" => "name" } }).map(fixture_rows[0])

      expect(result[:attrs].keys).to contain_exactly("name")
    end

    it "overrides defaults with non-blank mapped values" do
      result = build_mapper(
        columns: { "First Name" => { "target" => "name" } },
        defaults: { "name" => "Fallback", "country" => "us" }
      ).map(fixture_rows[0])

      expect(result[:attrs]).to include("name" => "Andrew", "country" => "us")
    end

    it "keeps the default when the mapped value is blank" do
      result = build_mapper(
        columns: { "Name" => { "target" => "name" } },
        defaults: { "name" => "Fallback" }
      ).map({ "Name" => "" })

      expect(result[:attrs]).to include("name" => "Fallback")
      expect(result[:errors]).to be_empty
    end

    it "coerces a date string into a datetime slot" do
      result = build_mapper(
        columns: { "Subscription Date" => { "target" => "property_datetime_1" } }
      ).map(fixture_rows[0])

      expect(result[:attrs]["property_datetime_1"]).to eq(Time.zone.parse("2021-07-26"))
      expect(result[:errors]).to be_empty
    end

    it "coerces booleans and decimals" do
      result = build_mapper(
        columns: {
          "Active" => { "target" => "property_boolean_1" },
          "Score" => { "target" => "property_decimal_1" }
        }
      ).map({ "Active" => "yes", "Score" => "12.5" })

      expect(result[:attrs]["property_boolean_1"]).to be(true)
      expect(result[:attrs]["property_decimal_1"]).to eq(BigDecimal("12.5"))
    end

    it "returns an error for a text value mapped to an enum-backed column" do
      result = build_mapper(columns: { "Country" => { "target" => "country" } }).map({ "Country" => "us" })

      expect(result[:errors]).to include("country: cannot parse 'us'")
      expect(result[:attrs]).not_to have_key("country")
    end

    it "returns an error for an unparseable integer" do
      result = build_mapper(columns: { "Index" => { "target" => "property_integer_1" } }).map({ "Index" => "abc" })

      expect(result[:errors]).to include("property_integer_1: cannot parse 'abc'")
      expect(result[:attrs]).not_to have_key("property_integer_1")
    end

    it "returns an error when a lookup target is missing" do
      columns = {
        "Branch Code" => {
          "target" => "branch_id",
          "lookup" => { "resource" => "branches", "by" => "external_id" }
        }
      }

      result = build_mapper(columns: columns).map({ "Branch Code" => "does-not-exist" })

      expect(result[:errors]).to include("branches: no record with external_id 'does-not-exist'")
      expect(result[:attrs]).not_to have_key("branch_id")
    end

    it "resolves a lookup by external_id when the record exists" do
      branch = create(:branch, company: company, external_id: "B-1")
      columns = {
        "Branch Code" => {
          "target" => "branch_id",
          "lookup" => { "resource" => "branches", "by" => "external_id" }
        }
      }

      result = build_mapper(columns: columns).map({ "Branch Code" => "B-1" })

      expect(result[:errors]).to be_empty
      expect(result[:attrs]["branch_id"]).to eq(branch.id)
    end
  end
end
