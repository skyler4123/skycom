# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::KpiService do
  let(:company) { create(:company) }
  let(:branch) do
    create(:branch, company: company).tap { |record| record.update_columns(discarded_at: nil) }
  end
  let!(:owner) do
    company.employees.find_by!(business_type: :owner).tap { |employee| employee.update!(branch: branch) }
  end
  let!(:staff) do
    create(:employee, company: company, branch: branch, name: "Staff")
  end
  let(:current_month) { Date.current.beginning_of_month }

  before do
    4.times { create_order }
  end

  describe ".create_samples!" do
    it "creates the active orders-sold KPI rule" do
      described_class.create_samples!(company: company)

      config = KpiConfig.find_by!(company: company, name: "Orders sold")

      expect(config.metric_key).to eq("orders_count")
      expect(config.target_value).to eq(5)
      expect(config).to be_workflow_status_active
      expect(config).to be_lifecycle_status_active
    end

    it "attributes a paid current-month order to the owner" do
      described_class.create_samples!(company: company)

      owner_paid_orders = owner.orders.where(workflow_status: :paid)

      expect(owner_paid_orders.count).to eq(1)
      expect(owner_paid_orders.first.created_at).to be >= current_month.beginning_of_day
    end

    it "gives staff a paid order and leaves one order unattributed" do
      described_class.create_samples!(company: company)

      expect(staff.orders.where(workflow_status: :paid).count).to eq(1)
      expect(company.orders.where(employee_id: nil).count).to eq(1)
    end

    it "builds a non-empty scorecard for the owner" do
      described_class.create_samples!(company: company)

      scorecard = Kpi::ScorecardService.call(
        company: company,
        employee: owner,
        from: current_month.beginning_of_day,
        to: current_month.end_of_month.end_of_day
      )

      expect(scorecard[:rows]).not_to be_empty
      expect(scorecard[:composite_pct]).to eq(20.0)
    end

    it "does not duplicate the config or re-attribute orders when run twice" do
      described_class.create_samples!(company: company)

      expect do
        described_class.create_samples!(company: company)
      end.not_to change {
        [
          KpiConfig.where(company: company).count,
          company.orders.where(employee_id: owner.id).count,
          company.orders.where(employee_id: nil).count
        ]
      }
    end

    it "keeps the same unattributed order when it is not the last order overall" do
      company.orders.destroy_all
      second_branch = create(:branch, company: company).tap { |record| record.update_columns(discarded_at: nil) }
      create_order
      unattributed = create_order
      create_order(second_branch)

      described_class.create_samples!(company: company)

      expect(unattributed.reload.employee_id).to be_nil
      expect { described_class.create_samples!(company: company) }
        .not_to change { unattributed.reload.employee_id }
    end
  end

  def create_order(target_branch = branch)
    customer = create(:customer, company: company)
    category = Seed::CategoryService.find_or_create_for(company: company, resource_name: "orders")

    company.orders.create!(
      branch: target_branch,
      customer: customer,
      category: category,
      property_mapping: category.default_property_mapping,
      name: "Seed order #{SecureRandom.hex(4)}",
      currency: :usd,
      business_type: :in_store,
      workflow_status: :pending
    )
  end
end
