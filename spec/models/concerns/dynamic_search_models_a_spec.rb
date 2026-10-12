require "rails_helper"

RSpec.describe "dynamic meilisearch models A (Answer → Order)" do
  include DynamicSearchModelHelpers

  before(:all) do
    @meili_available = begin
      Meilisearch::Rails.client.health["status"] == "available"
    rescue StandardError
      false
    end
    unless @meili_available
      raise "Meilisearch not reachable at #{Meilisearch::Rails.configuration[:meilisearch_url]}. Run `docker compose up -d meilisearch`."
    end
  end

  DYNAMIC_SEARCH_MODELS.slice(
    Answer,
    Branch,
    Brand,
    Cart,
    CartGroup,
    Customer,
    CustomerGroup,
    Department,
    Document,
    Employee,
    EmployeeGroup,
    Event,
    EventGroup,
    Exam,
    ExamGroup,
    Facility,
    FacilityGroup,
    Invoice,
    Membership,
    Order
  ).each do |model_class, builder|
    it_behaves_like "dynamic meilisearch model", model_class, builder
  end
end
