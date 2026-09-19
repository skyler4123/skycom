# spec/models/workflow_spec.rb
require "rails_helper"

RSpec.describe Workflow, type: :model do
  let(:company) { create(:company) }
  let(:category) { create(:category, company: company, name: "Office Supplies", resource_name: "purchases") }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
    it { should have_many(:workflow_steps).dependent(:destroy) }
    it { should have_many(:workflow_step_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }

    it "rejects duplicate names within the same company" do
      create(:workflow, company: company, category: category, name: "Standard")
      expect { create(:workflow, company: company, name: "Standard") }
        .to raise_error(ActiveRecord::RecordInvalid, /Name has already been taken/)
    end

    it "rejects a category from another company" do
      foreign_category = create(:category, name: "Foreign supplies", resource_name: "purchases")

      expect { create(:workflow, company: company, category: foreign_category, name: "Standard") }
        .to raise_error(ActiveRecord::RecordInvalid, /same company/)
    end
  end

  describe "one workflow per category" do
    it "rejects a second workflow for the same category" do
      create(:workflow, company: company, category: category, name: "First")

      expect { create(:workflow, company: company, category: category, name: "Second") }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows workflows on different categories" do
      other_category = create(:category, company: company, name: "Equipment", resource_name: "purchases")
      create(:workflow, company: company, category: category, name: "First")

      expect { create(:workflow, company: company, category: other_category, name: "Second") }
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

  describe "category bridge" do
    it "is reachable as the category's default workflow" do
      workflow = create(:workflow, company: company, category: category, name: "Standard")

      expect(category.reload.default_workflow).to eq(workflow)
    end

    it "releases purchase pointers before its steps are destroyed" do
      workflow = create(:workflow, company: company, category: category, name: "Standard")
      step = create(:workflow_step, workflow: workflow, name: "Submit", position: 1)
      purchase = create(:purchase, company: company, category: category, name: "Pens restock")
      purchase.update_columns(workflow_step_id: step.id)

      workflow.destroy

      expect(Purchase.find(purchase.id).workflow_step_id).to be_nil
    end
  end
end
