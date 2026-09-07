# frozen_string_literal: true

require "rails_helper"

RSpec.describe DynamicSearch::BaseQueryService do
  let(:company) { create(:company) }

  def build_service(model, params)
    # define_singleton_method blocks DO capture the local; `def self.model = model` would not.
    klass = Class.new(described_class)
    klass.define_singleton_method(:model) { model }
    klass.define_singleton_method(:fallback_resource_name) { nil }
    klass.new(company: company, params: ActionController::Parameters.new(params))
  end

  describe "filter_string column guards" do
    it "adds category_id + branch_id clauses when the model has the columns" do
      s = build_service(Customer, category_id: "c-1", branch_id: "b-1", q: "x")

      expect(s.filter_string).to include(%(category_id = "c-1"))
      expect(s.filter_string).to include(%(branch_id = "b-1"))
    end

    it "omits the branch_id clause when the model has no branch_id column" do
      s = build_service(Branch, branch_id: "b-1", q: "x")

      expect(s.filter_string).not_to include("branch_id")
      expect(s.filter_string).to include(%(company_id = "#{company.id}"))
    end

    it "omits the category_id clause when the model has no category_id column" do
      s = build_service(User, category_id: "c-1", q: "x")

      expect(s.filter_string).not_to include("category_id")
    end
  end

  describe "#record_ids" do
    it "is nil when not active" do
      expect(build_service(Customer, {}).record_ids).to be_nil
    end

    it "hits Meilisearch only once across calls (memoized)" do
      s = build_service(Customer, q: "x")
      allow(s).to receive(:active?).and_return(true)
      expect(Customer).to receive(:ms_raw_search).once.and_return({ "hits" => [ { "id" => "a" } ] })

      expect(s.record_ids).to eq([ "a" ])
      expect(s.record_ids).to eq([ "a" ])
    end
  end
end
