# spec/models/question_spec.rb
require "rails_helper"

RSpec.describe Question, type: :model do
  describe "associations" do
    it { should belong_to(:company) }
    it { should belong_to(:category) }
    it { should have_many(:question_options).dependent(:destroy) }
    it { should have_many(:exam_question_appointments).dependent(:destroy) }
    it { should have_many(:employee_question_appointments).dependent(:destroy) }
  end
end
