# spec/models/workflow_spec.rb
require "rails_helper"

RSpec.describe Workflow, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:workflow_steps).dependent(:destroy) }
    it { should have_many(:workflow_step_logs).dependent(:destroy) }
    it { should have_many(:purchases) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }

    it "rejects a second default for the same process in the same company" do
      company = create(:company)
      create(:workflow, company: company, process_type: :purchase_process, is_default: true, name: "First")

      expect { create(:workflow, company: company, process_type: :purchase_process, is_default: true, name: "Second") }
        .to raise_error(ActiveRecord::RecordInvalid, /default workflow for this process/)
    end

    it "allows defaults for different process types" do
      company = create(:company)
      create(:workflow, company: company, process_type: :purchase_process, is_default: true, name: "Purchase default")

      expect { create(:workflow, company: company, process_type: :leave_process, is_default: true, name: "Leave default") }
        .not_to raise_error
    end

    it "allows a non-default workflow alongside a default" do
      company = create(:company)
      create(:workflow, company: company, process_type: :purchase_process, is_default: true, name: "Purchase default")

      expect { create(:workflow, company: company, process_type: :purchase_process, is_default: false, name: "Express buy") }
        .not_to raise_error
    end
  end

  describe "enums" do
    it { should define_enum_for(:process_type) }
    it { should define_enum_for(:lifecycle_status) }

    it "defines process_type values" do
      expect(Workflow.process_types).to eq("purchase_process" => 0, "leave_process" => 1)
    end
  end

  describe ".default_for" do
    it "returns the active default workflow for the process" do
      company = create(:company)
      default = create(:workflow, company: company, process_type: :purchase_process, is_default: true, name: "Default")
      create(:workflow, company: company, process_type: :purchase_process, is_default: false, name: "Express")
      create(:workflow, company: company, process_type: :leave_process, is_default: true, name: "Leave default")

      expect(company.workflows.default_for(:purchase_process)).to contain_exactly(default)
    end

    it "excludes inactive defaults" do
      company = create(:company)
      create(:workflow, company: company, process_type: :purchase_process, is_default: true,
        name: "Archived default", lifecycle_status: :archived)

      expect(company.workflows.default_for(:purchase_process)).to be_empty
    end
  end
end
