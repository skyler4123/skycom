# spec/jobs/exams/summary_job_spec.rb
require "rails_helper"

RSpec.describe Exams::SummaryJob, type: :job do
  let(:exam) { create(:exam) }
  let(:employee) { create(:employee, company: exam.company) }

  it "computes and stores the exam summary" do
    create(
      :employee_exam_appointment,
      exam: exam,
      employee: employee,
      workflow_status: :graded,
      score: 80,
      passed: true,
      attempt_number: 1,
      started_at: 1.hour.ago,
      submitted_at: 30.minutes.ago,
      graded_at: 20.minutes.ago
    )

    described_class.perform_now(exam.id)

    summary = exam.reload.exam_summary
    expect(summary).to be_present
    expect(summary.passed_count).to eq(1)
    expect(summary.pass_rate).to eq(100)
  end

  it "no-ops when the exam no longer exists" do
    expect { described_class.perform_now(SecureRandom.uuid) }.not_to raise_error
  end
end
