# spec/jobs/exams/expire_attempts_job_spec.rb
require "rails_helper"

RSpec.describe Exams::ExpireAttemptsJob, type: :job do
  let(:company) { create(:company) }
  let(:overdue_exam) { create(:exam, company: company, duration_minutes: 1) }
  let(:future_exam) { create(:exam, company: company, duration_minutes: 30) }
  let(:overdue_employee) { create(:employee, company: company) }
  let(:future_employee) { create(:employee, company: company) }

  it "expires overdue attempts and leaves future attempts alone" do
    overdue = start_exam!(overdue_exam, overdue_employee)
    future = start_exam!(future_exam, future_employee)

    travel_to(overdue.deadline_at + 1.second) do
      described_class.perform_now

      expect(overdue.reload.workflow_status).to eq("expired")
      expect(future.reload.workflow_status).to eq("in_progress")
    end
  end
end
