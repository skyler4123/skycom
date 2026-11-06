# spec/requests/companies/questions_controller_spec.rb
require "rails_helper"

RSpec.describe "Companies::QuestionsController", type: :request do
  let(:company) { create(:company) }
  let(:category) { create(:category, company: company, resource_name: "questions") }
  let(:question) { create(:question, company: company, category: category) }

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
    it "returns the company's questions with pagination" do
      question
      other = create(:question, company: company, category: category, question_type: :text)

      get "/companies/#{company.id}/questions.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["questions"].map { |entry| entry["id"] }).to include(question.id, other.id)
      expect(body["pagination"]).to be_present
      expect(body["questions"].first).to have_key("options_count")
    end

    it "filters by query, category, and type" do
      matching = create(:question, company: company, category: category, name: "Safety first")
      create(:question, company: company, category: category, name: "Other", question_type: :text)
      other_category = create(:category, company: company, resource_name: "questions")
      create(:question, company: company, category: other_category, name: "Safety elsewhere")

      get "/companies/#{company.id}/questions.json", params: { q: "Safety", category_id: category.id, question_type: "single_choice" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["questions"].map { |entry| entry["id"] }).to contain_exactly(matching.id)
    end

    it "does not leak another company's questions" do
      other_company_question = create(:question)

      get "/companies/#{company.id}/questions.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["questions"].map { |entry| entry["id"] }).not_to include(other_company_question.id)
    end
  end

  describe "GET #show" do
    it "returns the question with ordered options and usage count" do
      exam = create(:exam, company: company, questions_count: 0)
      exam.exam_question_appointments.create!(question: question, position: 0)

      get "/companies/#{company.id}/questions/#{question.id}.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["question"]["id"]).to eq(question.id)
      expect(body["question"]["options"].map { |option| option["content"] }).to eq(question.question_options.order(:position).map(&:content))
      expect(body["usage_count"]).to eq(1)
    end

    it "returns 404 for another company's question" do
      other_question = create(:question)

      get "/companies/#{company.id}/questions/#{other_question.id}.json"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #new" do
    it "returns question categories and types, creating a default category when needed" do
      get "/companies/#{company.id}/questions/new.json"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["categories"]).not_to be_empty
      expect(body["question_types"].map { |entry| entry["value"] }).to match_array(%w[single_choice true_false text])
      expect(body["categories"].map { |entry| entry["resource_name"] }.uniq).to eq([ "questions" ])
    end
  end

  describe "POST #create" do
    it "creates a single-choice question with options" do
      post "/companies/#{company.id}/questions.json", params: {
        question: {
          name: "What is 2 + 2?",
          description: "Arithmetic",
          category_id: category.id,
          question_type: "single_choice",
          points: 2,
          options: {
            "0" => { content: "3" },
            "1" => { content: "4" }
          },
          correct_option_index: 1
        }
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["message"]).to eq("Question created successfully.")
      created = Question.find(body["question"]["id"])
      expect(created.name).to eq("What is 2 + 2?")
      expect(created.points).to eq(2)
      expect(created.question_options.order(:position).map(&:content)).to eq([ "3", "4" ])
      expect(created.correct_option.content).to eq("4")
    end

    it "creates a true/false question" do
      post "/companies/#{company.id}/questions.json", params: {
        question: {
          name: "The sky is blue",
          category_id: category.id,
          question_type: "true_false",
          points: 1,
          options: {
            "0" => { content: "True" },
            "1" => { content: "False" }
          },
          correct_option_index: 0
        }
      }

      expect(response).to have_http_status(:created)
      created = Question.find(JSON.parse(response.body)["question"]["id"])
      expect(created).to be_true_false
      expect(created.question_options.count).to eq(2)
      expect(created.correct_option.content).to eq("True")
    end

    it "creates a text question with a model answer" do
      post "/companies/#{company.id}/questions.json", params: {
        question: {
          name: "Explain safety",
          category_id: category.id,
          question_type: "text",
          points: 1,
          correct_text: "Wear protective equipment"
        }
      }

      expect(response).to have_http_status(:created)
      created = Question.find(JSON.parse(response.body)["question"]["id"])
      expect(created).to be_text
      expect(created.correct_text).to eq("Wear protective equipment")
      expect(created.question_options).to be_empty
    end

    it "returns errors for an invalid question" do
      post "/companies/#{company.id}/questions.json", params: {
        question: {
          name: "Broken",
          category_id: category.id,
          question_type: "single_choice",
          points: 1,
          options: { "0" => { content: "Only one" } },
          correct_option_index: 0
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_an(Array)
      expect(body["errors"].join(" ")).to include("at least two options")
    end

    it "rejects a category from another resource" do
      product_category = create(:category, company: company, resource_name: "products")

      post "/companies/#{company.id}/questions.json", params: {
        question: {
          name: "Wrong category",
          category_id: product_category.id,
          question_type: "text",
          points: 1
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join(" ")).to include("question category")
    end
  end

  describe "PATCH #update" do
    it "replaces options and moves the correct flag" do
      patch "/companies/#{company.id}/questions/#{question.id}.json", params: {
        question: {
          name: "Updated question",
          category_id: category.id,
          question_type: "single_choice",
          points: 3,
          options: {
            "0" => { content: "Alpha" },
            "1" => { content: "Beta" }
          },
          correct_option_index: 0
        }
      }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Question updated successfully.")
      question.reload
      expect(question.name).to eq("Updated question")
      expect(question.points).to eq(3)
      expect(question.question_options.order(:position).map(&:content)).to eq([ "Alpha", "Beta" ])
      expect(question.correct_option.content).to eq("Alpha")
    end
  end

  describe "DELETE #destroy" do
    it "deletes an unused question" do
      question

      expect do
        delete "/companies/#{company.id}/questions/#{question.id}.json"
      end.to change(Question, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["message"]).to eq("Question deleted successfully.")
    end

    it "refuses to delete a question used by an exam" do
      exam = create(:exam, company: company, questions_count: 0)
      exam.exam_question_appointments.create!(question: question, position: 0)

      expect do
        delete "/companies/#{company.id}/questions/#{question.id}.json"
      end.not_to change(Question, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join(" ")).to include("used")
    end
  end

  describe "authorization" do
    it "forbids an employee without Question read permission" do
      employee = create(:employee, company: company)
      get sign_in_for_test_path(email: employee.user.email)

      get "/companies/#{company.id}/questions.json"

      expect(response).to have_http_status(:forbidden)
    end
  end
end
