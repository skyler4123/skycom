require "rails_helper"
require_relative "../../support/dynamic_search_models"
require_relative "../../support/shared_examples/dynamic_search"

RSpec.describe "dynamic meilisearch models (07: Project–Service)" do
  before(:all) do
    raise "Meilisearch not reachable. Run `docker compose up -d meilisearch`." unless begin
      Meilisearch::Rails.client.health["status"] == "available"
    rescue StandardError
      false
    end
  end

  include DynamicSearchModelBuilders

  DYNAMIC_SEARCH_MODELS.slice(Project, ProjectGroup, Question, Reservation, Service).each do |model_class, builder|
    it_behaves_like "dynamic meilisearch model", model_class, builder
  end
end
