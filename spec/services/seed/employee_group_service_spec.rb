# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::EmployeeGroupService do
  describe ".ensure_defaults!" do
    let(:company) { create(:company) }

    it "creates the default category and table config" do
      category = described_class.ensure_defaults!(company: company)

      expect(category.name).to eq("Employee Groups")
      expect(category.resource_name).to eq("employee_groups")
      expect(category.table_configs.count).to eq(1)

      columns = category.table_configs.first.columns.map { |column| column["key"] }
      expect(columns).to include("name", "manager", "employees_count")
    end

    it "never overwrites an existing table config" do
      category = described_class.ensure_defaults!(company: company)
      table_config = category.table_configs.first
      table_config.update!(name: "Custom employee group table")

      described_class.ensure_defaults!(company: company)

      expect(category.table_configs.reload.count).to eq(1)
      expect(table_config.reload.name).to eq("Custom employee group table")
    end
  end
end
