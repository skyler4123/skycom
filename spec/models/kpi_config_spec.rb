require "rails_helper"

RSpec.describe KpiConfig, type: :model do
  let(:company) { create(:company) }
  subject(:kpi_config) { build(:kpi_config, company: company) }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category).optional }
    it { should belong_to(:branch).optional }
    it { should belong_to(:department).optional }
    it { should belong_to(:role).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:metric_key) }
    it { should validate_presence_of(:period_type) }
    it { should validate_presence_of(:direction) }
    it { should validate_numericality_of(:weight).is_greater_than(0) }
    it { should validate_numericality_of(:target_value).is_greater_than_or_equal_to(0).allow_nil }

    it "rejects an unknown metric key" do
      kpi_config.metric_key = "unknown_metric"

      expect(kpi_config).not_to be_valid
      expect(kpi_config.errors[:metric_key]).to include("is not included in the list")
    end

    it "accepts a registered metric key" do
      kpi_config.metric_key = "orders_count"

      expect(kpi_config).to be_valid
    end

    it "requires a unique name per company" do
      create(:kpi_config, company: kpi_config.company, name: "Sales")
      kpi_config.name = "Sales"

      expect(kpi_config).not_to be_valid
      expect(kpi_config.errors[:name]).to include("has already been taken")
    end

    it "rejects a scope record from another company" do
      kpi_config.category = create(:category)

      expect(kpi_config).not_to be_valid
      expect(kpi_config.errors[:category]).to include("must belong to the same company")
    end
  end

  describe "#applies_to?" do
    let(:company) { create(:company) }
    let(:branch) { create(:branch, company: company) }
    let(:employee) { create(:employee, company: company, branch: branch) }

    it "applies to every employee when no scope is set" do
      config = build(:kpi_config, company: company)

      expect(config.applies_to?(employee)).to be(true)
    end

    it "matches the employee category" do
      config = build(:kpi_config, company: company, category: employee.category)

      expect(config.applies_to?(employee)).to be(true)
    end

    it "rejects a different category" do
      config = build(:kpi_config, company: company, category: create(:category, company: company))

      expect(config.applies_to?(employee)).to be(false)
    end

    it "matches a department membership" do
      department = create(:department, company: company)
      DepartmentEmployeeAppointment.create!(company: company, department: department, employee: employee)
      config = build(:kpi_config, company: company, department: department)

      expect(config.applies_to?(employee)).to be(true)
    end

    it "matches a role membership" do
      role = create(:role, company: company)
      create(:employee_role_appointment, company: company, employee: employee, role: role)
      config = build(:kpi_config, company: company, role: role)

      expect(config.applies_to?(employee)).to be(true)
    end

    it "ignores a discarded department appointment" do
      department = create(:department, company: company)
      DepartmentEmployeeAppointment.create!(company: company, department: department, employee: employee,
        discarded_at: Time.current)
      config = build(:kpi_config, company: company, department: department)

      expect(config.applies_to?(employee)).to be(false)
    end

    it "ignores a discarded role appointment" do
      role = create(:role, company: company)
      EmployeeRoleAppointment.create!(company: company, role: role, employee: employee, discarded_at: Time.current)
      config = build(:kpi_config, company: company, role: role)

      expect(config.applies_to?(employee)).to be(false)
    end

    it "requires every configured scope to match" do
      config = build(
        :kpi_config,
        company: company,
        branch: create(:branch, company: company),
        category: employee.category
      )

      expect(config.applies_to?(employee)).to be(false)
    end
  end
end
