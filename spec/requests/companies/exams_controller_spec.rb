# spec/requests/companies/exams_controller_spec.rb
require "rails_helper"

RSpec.describe "Companies::ExamsController", type: :request, active_job: true do
  let(:company) { create(:company) }
  let(:category) { create(:category, company: company, resource_name: "questions") }
  let(:exam) { create(:exam, company: company) }

  before do
    get sign_in_for_test_path(email: company.user.email)
  end

  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  describe "GET #index" do
    it "returns exams with counts and summaries" do
      create(:exam_summary, exam: exam, assigned_count: 3, pass_rate: 50)
      create(:exam, company: company, name: "Draft exam")

      get "/companies/#{company.id}/exams.json", params: { q: exam.name, workflow_status: "draft" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["exams"].map { |entry| entry["id"] }).to include(exam.id)
      expect(body["pagination"]).to be_present
      entry = body["exams"].find { |row| row["id"] == exam.id }
      expect(entry["questions_count"]).to eq(exam.exam_question_appointments.count)
      expect(entry["assigned_count"]).to eq(3)
      expect(entry["summary"]["pass_rate"].to_f).to eq(50)
    end

    it "does not leak another company's exams" do
      other = create(:exam)

      get "/companies/#{company.id}/exams.json"

      body = JSON.parse(response.body)
      expect(body["exams"].map { |entry| entry["id"] }).not_to include(other.id)
    end
  end

  describe "GET #show" do
    it "returns questions in order, summary, and recent attempts" do
      employee = create(:employee, company: company)
      create(:employee_exam_appointment, exam: exam, employee: employee, workflow_status: :graded, score: 80, passed: true)
      create(:exam_summary, exam: exam, assigned_count: 1, passed_count: 1, graded_count: 1, pass_rate: 100)

      get "/companies/#{company.id}/exams/#{exam.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["exam"]["id"]).to eq(exam.id)
      expect(body["questions"].map { |entry| entry["id"] }).to eq(exam.questions.map(&:id))
      expect(body["summary"]["pass_rate"].to_f).to eq(100)
      expect(body["recent_appointments"].first["employee"]["name"]).to eq(employee.name)
    end

    it "returns 404 for another company's exam" do
      other = create(:exam)

      get "/companies/#{company.id}/exams/#{other.id}.json"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #new / #edit" do
    it "returns question picker reference data" do
      question = create(:question, company: company, category: category)

      get "/companies/#{company.id}/exams/new.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["questions"].map { |entry| entry["id"] }).to include(question.id)
      expect(body["categories"].map { |entry| entry["id"] }).to include(category.id)
      expect(body["question_types"]).to be_present
    end

    it "returns the exam with ordered question_ids" do
      get "/companies/#{company.id}/exams/#{exam.id}/edit.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["exam"]["question_ids"]).to eq(exam.questions.map(&:id))
    end
  end

  describe "POST #create" do
    it "creates a draft exam with ordered questions and normalized blanks" do
      questions = create_list(:question, 2, company: company, category: category)

      post "/companies/#{company.id}/exams.json", params: {
        exam: {
          name: "Workplace Safety",
          description: "Annual safety exam",
          duration_minutes: "",
          passing_score: 75,
          max_attempts: "",
          shuffle_options: "true",
          question_ids: [ questions[1].id, questions[0].id ]
        }
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Exam created successfully.")
      created = Exam.find(body["exam"]["id"])
      expect(created.duration_minutes).to be_nil
      expect(created.max_attempts).to be_nil
      expect(created.questions.map(&:id)).to eq([ questions[1].id, questions[0].id ])
    end

    it "returns errors for invalid input" do
      post "/companies/#{company.id}/exams.json", params: {
        exam: { name: "", passing_score: 120 }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"]).to be_an(Array)
    end
  end

  describe "PATCH #update" do
    it "reorders and removes questions" do
      questions = create_list(:question, 2, company: company, category: category)
      exam.exam_question_appointments.destroy_all
      questions.each_with_index { |question, index| exam.exam_question_appointments.create!(question: question, position: index) }

      patch "/companies/#{company.id}/exams/#{exam.id}.json", params: {
        exam: {
          name: "Updated exam",
          duration_minutes: 45,
          passing_score: 80,
          max_attempts: 2,
          shuffle_options: "false",
          question_ids: [ questions[1].id ]
        }
      }

      expect(response).to have_http_status(:ok)
      exam.reload
      expect(exam.name).to eq("Updated exam")
      expect(exam.duration_minutes).to eq(45)
      expect(exam.questions.map(&:id)).to eq([ questions[1].id ])
    end
  end

  describe "POST #publish / #archive / #refresh_summary" do
    it "refuses to publish an empty exam" do
      empty_exam = create(:exam, company: company, questions_count: 0)

      post "/companies/#{company.id}/exams/#{empty_exam.id}/publish.json"

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join(" ")).to include("Add at least one question")
    end

    it "publishes an exam with questions" do
      post "/companies/#{company.id}/exams/#{exam.id}/publish.json"

      expect(response).to have_http_status(:ok)
      expect(exam.reload.workflow_status).to eq("published")
      expect(exam.published_at).to be_present
    end

    it "archives an exam" do
      post "/companies/#{company.id}/exams/#{exam.id}/archive.json"

      expect(response).to have_http_status(:ok)
      expect(exam.reload.workflow_status).to eq("archived")
    end

    it "enqueues a summary refresh" do
      expect do
        post "/companies/#{company.id}/exams/#{exam.id}/refresh_summary.json"
      end.to have_enqueued_job(Exams::SummaryJob).with(exam.id)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Summary refresh queued.")
    end
  end

  describe "DELETE #destroy" do
    it "deletes an exam without attempts" do
      exam

      expect do
        delete "/companies/#{company.id}/exams/#{exam.id}.json"
      end.to change(Exam, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "refuses to delete an exam with attempts" do
      employee = create(:employee, company: company)
      create(:employee_exam_appointment, exam: exam, employee: employee)

      expect do
        delete "/companies/#{company.id}/exams/#{exam.id}.json"
      end.not_to change(Exam, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join(" ")).to include("attempts")
    end
  end

  describe "authorization" do
    it "forbids an employee without Exam read permission" do
      employee = create(:employee, company: company)
      get sign_in_for_test_path(email: employee.user.email)

      get "/companies/#{company.id}/exams.json"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
