# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::ExamSampleService do
  let(:company) { create(:company) }
  let!(:staff) { create_list(:employee, 8, company: company) }
  let!(:question_categories) do
    %w[General Safety Compliance Customer\ Service].map do |name|
      Category.find_or_create_by!(company: company, resource_name: "questions", name: name)
    end
  end

  describe ".seed_for" do
    it "creates a numbered question bank across the question categories" do
      described_class.seed_for(company: company)

      questions = company.questions.includes(:question_options).to_a
      names = (1..12).map { |number| "Question #{number}" }
      descriptions = (1..12).map { |number| "Question title #{number}" }

      expect(questions.map(&:name)).to match_array(names)
      expect(questions.map(&:description)).to match_array(descriptions)
      expect(questions.map(&:category_id).uniq).to match_array(question_categories.map(&:id))
      expect(question_categories.map { |category| questions.count { |question| question.category_id == category.id } }).to eq([ 3, 3, 3, 3 ])

      expect(questions.count(&:single_choice?)).to eq(8)
      expect(questions.count(&:true_false?)).to eq(2)
      expect(questions.count(&:text?)).to eq(2)

      single_choice_questions = questions.select(&:single_choice?)
      expect(single_choice_questions.map { |question| question.question_options.order(:position).pluck(:content) }.uniq)
        .to eq([ %w[Question\ Option\ 1 Question\ Option\ 2 Question\ Option\ 3 Question\ Option\ 4] ])
      expect(single_choice_questions.map { |question| question.question_options.find_by(correct: true).content }.uniq)
        .to eq([ "Question Option 1" ])

      expect(questions.select(&:text?).map(&:correct_text)).to match_array([ "Question answer 6", "Question answer 12" ])
      expect(questions.select(&:text?).map(&:points).uniq).to eq([ 2 ])
      expect(questions.reject(&:text?).map(&:points).uniq).to eq([ 1 ])
    end

    it "creates exams in every workflow status with attempts across the lifecycle" do
      described_class.seed_for(company: company)

      exams = company.exams.includes(:exam_summary).to_a
      expect(exams.map(&:name)).to match_array((1..5).map { |number| "Exam #{number}" })
      expect(exams.map(&:workflow_status).tally).to eq("published" => 3, "draft" => 1, "archived" => 1)

      exam_one = company.exams.find_by!(name: "Exam 1")
      expect(exam_one.exam_question_appointments.count).to eq(8)
      expect(exam_one.questions.map(&:question_type).uniq).to match_array(%w[single_choice true_false])
      expect(exam_one.employee_exam_appointments.distinct.count(:employee_id)).to eq(7)
      expect(exam_one.employee_exam_appointments.pluck(:workflow_status))
        .to include("graded", "assigned", "in_progress", "expired")
      expect(staff[6].employee_exam_appointments.where(exam: exam_one)).to be_empty
      expect(staff[7].employee_exam_appointments.where(exam: exam_one)).to be_empty

      exam_two = company.exams.find_by!(name: "Exam 2")
      expect(exam_two.exam_question_appointments.count).to eq(6)
      expect(exam_two.questions.count(&:text?)).to eq(2)
      expect(exam_two.employee_exam_appointments.count).to eq(5)
      expect(exam_two.employee_exam_appointments.pluck(:workflow_status))
        .to include("in_progress", "submitted", "graded", "assigned")

      exam_three = company.exams.find_by!(name: "Exam 3")
      expect(exam_three.employee_exam_appointments.count).to eq(2)
      expect(exam_three.employee_exam_appointments.pluck(:workflow_status)).to match_array(%w[assigned assigned])

      expect(company.exams.find_by!(name: "Exam 4")).to be_workflow_status_draft
      expect(company.exams.find_by!(name: "Exam 4").employee_exam_appointments).to be_empty
      expect(company.exams.find_by!(name: "Exam 5")).to be_workflow_status_archived

      summary_one = exam_one.exam_summary
      expect(summary_one).to be_present
      expect(summary_one.assigned_count).to eq(7)
      expect(summary_one.graded_count).to eq(4)
      expect(summary_one.passed_count).to eq(3)
      expect(summary_one.failed_count).to eq(1)
      expect(summary_one.expired_count).to eq(1)
      expect(summary_one.pass_rate).to eq(75)
      expect(summary_one.average_score).to eq(68.75)
      expect(summary_one.highest_score).to eq(100)
      expect(summary_one.lowest_score).to eq(12.5)
      expect(summary_one.question_stats).not_to be_empty

      summary_two = exam_two.exam_summary
      expect(summary_two).to be_present
      expect(summary_two.assigned_count).to eq(5)
      expect(summary_two.graded_count).to eq(2)
      expect(summary_two.passed_count).to eq(1)
      expect(summary_two.failed_count).to eq(1)
      expect(summary_two.pending_review_count).to eq(1)
      expect(summary_two.pass_rate).to eq(50)
      expect(summary_two.average_score).to eq(68.75)
      expect(summary_two.highest_score).to eq(100)
      expect(summary_two.lowest_score).to eq(37.5)

      summary_three = exam_three.exam_summary
      expect(summary_three).to be_present
      expect(summary_three.assigned_count).to eq(2)
      expect(summary_three.graded_count).to eq(0)
    end

    it "gives the owner one exam in each My Exams tab" do
      described_class.seed_for(company: company)

      owner = company.employees.find_by!(business_type: :owner)
      statuses = owner.employee_exam_appointments
        .joins(:exam)
        .where(exams: { workflow_status: :published })
        .pluck(:workflow_status)

      expect(statuses).to match_array(%w[graded in_progress assigned])
    end
  end
end
