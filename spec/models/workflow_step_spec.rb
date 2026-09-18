# spec/models/workflow_step_spec.rb
require "rails_helper"

RSpec.describe WorkflowStep, type: :model do
  let(:company) { create(:company) }
  let(:workflow) { create(:workflow, company: company, name: "Standard Purchase Process") }

  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:workflow) }
    it { should have_many(:workflow_step_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(255) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(1) }

    it "rejects a duplicate position within the same workflow" do
      create(:workflow_step, workflow: workflow, name: "Submit", position: 1)

      expect { create(:workflow_step, workflow: workflow, name: "Another first", position: 1) }
        .to raise_error(ActiveRecord::RecordInvalid, /Position has already been taken/)
    end

    it "allows the same position in different workflows" do
      other = create(:workflow, company: company, name: "Other flow")
      create(:workflow_step, workflow: workflow, name: "Submit", position: 1)

      expect { create(:workflow_step, workflow: other, name: "Submit", position: 1) }.not_to raise_error
    end
  end

  describe "#next_step / #previous_step" do
    it "walks steps in position order" do
      submit = create(:workflow_step, workflow: workflow, name: "Submit", position: 1)
      approval = create(:workflow_step, workflow: workflow, name: "Manager Approval", position: 2)
      buy = create(:workflow_step, workflow: workflow, name: "Buy", position: 3)

      expect(submit.next_step).to eq(approval)
      expect(approval.next_step).to eq(buy)
      expect(buy.next_step).to be_nil
      expect(buy.previous_step).to eq(approval)
      expect(submit.previous_step).to be_nil
    end
  end
end
