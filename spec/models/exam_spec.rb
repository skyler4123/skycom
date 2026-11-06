# spec/models/exam_spec.rb
require "rails_helper"

RSpec.describe Exam, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should have_many(:exam_question_appointments).dependent(:destroy) }
    it { should have_many(:employee_exam_appointments).dependent(:destroy) }
    it { should have_one(:exam_summary).dependent(:destroy) }
  end
end
