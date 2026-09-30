# frozen_string_literal: true

require "rails_helper"

# The five uniform calendar_* CRUD controllers (positions, practitioners,
# locations, equipments, participants, procedures) share one contract, so they
# share one spec. Any divergence between them is a bug.
RSpec.describe "Companies::Calendar resource controllers", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
    ActionController::Base.allow_forgery_protection = original
  end

  # [path segment, model, params key, json key, minimal valid attributes, search term]
  RESOURCES = [
    [ "calendar_positions", CalendarPosition, :calendar_position, "calendar_positions",
      { name: "Dentist", color: "#6366f1", default_duration_minutes: 30 }, "Dentist" ],
    [ "calendar_locations", CalendarLocation, :calendar_location, "calendar_locations",
      { name: "Surgery Room 1", color: "#0ea5e9", capacity: 1 }, "Surgery" ],
    [ "calendar_equipments", CalendarEquipment, :calendar_equipment, "calendar_equipments",
      { name: "X-Ray", color: "#f59e0b", quantity: 1 }, "X-Ray" ],
    [ "calendar_participants", CalendarParticipant, :calendar_participant, "calendar_participants",
      { name: "Patient A" }, "Patient" ],
    [ "calendar_procedures", CalendarProcedure, :calendar_procedure, "calendar_procedures",
      { name: "Tooth Extraction", slug: "tooth-extraction", duration_minutes: 60 }, "Extraction" ]
  ].freeze

  let(:company) { create(:company) }
  let(:owner) { company.user }

  before { get sign_in_for_test_path(email: owner.email) }

  # A procedure needs a position; the others do not.
  def build_record(model, attributes)
    scope = company.public_send(model.name.tableize)
    return scope.create!(attributes) if model == CalendarProcedure

    scope.create!(attributes)
  end

  # calendar_positions -> calendar_position
  def singular_key(segment) = segment.sub(/s\z/, "")

  def new_path_for(segment) = public_send(:"new_company_#{segment.singularize}_path", company)
  def index_path_for(segment, **query) = public_send(:"company_#{segment}_path", company, query)
  def member_path_for(segment, id) = public_send(:"company_#{segment.singularize}_path", company, id)
  def edit_path_for(segment, id) = public_send(:"edit_company_#{segment.singularize}_path", company, id)

  RESOURCES.each do |segment, model, params_key, json_key, attributes, term|
    describe "Companies::#{model.name.pluralize}Controller" do
      # Only CalendarProcedure needs one; lazy so it cannot leak into the
      # calendar_positions listing assertions.
      let(:position) { create(:calendar_position, company: company) }
      let(:valid_attributes) { model == CalendarProcedure ? attributes.merge(calendar_position_id: position.id) : attributes }

      it "renders the index shell" do
        get index_path_for(segment)
        expect(response).to have_http_status(:ok)
      end

      it "lists the company's records with pagination" do
        build_record(model, valid_attributes)

        get index_path_for(segment), as: :json

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body[json_key].size).to eq(1)
        expect(body).to have_key("pagination")
      end

      it "searches with ?q=" do
        build_record(model, valid_attributes)

        get index_path_for(segment, q: term), as: :json

        expect(JSON.parse(response.body)[json_key].size).to eq(1)
      end

      it "returns nothing for a search with no match" do
        build_record(model, valid_attributes)

        get index_path_for(segment, q: "zzzzzzzz-nope"), as: :json

        expect(JSON.parse(response.body)[json_key]).to be_empty
      end

      it "creates a record" do
        post index_path_for(segment), params: { params_key => valid_attributes }, as: :json

        expect(response).to have_http_status(:ok)
        # index returns the plural collection key; create/update/show/edit return
        # the singular one.
        expect(JSON.parse(response.body)[singular_key(segment)]).to be_present
        expect(model.where(company: company).count).to eq(1)
      end

      it "returns errors (plural array) on invalid input" do
        post index_path_for(segment), params: { params_key => {} }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(JSON.parse(response.body)["errors"]).to be_an(Array)
      end

      it "updates a record" do
        record = build_record(model, valid_attributes)
        renamed = valid_attributes.merge(name: "Renamed #{segment}")

        patch member_path_for(segment, record.id), params: { params_key => renamed }, as: :json

        expect(response).to have_http_status(:ok)
        expect(record.reload.name).to eq("Renamed #{segment}")
      end

      it "destroys a record" do
        record = build_record(model, valid_attributes)

        delete member_path_for(segment, record.id), as: :json

        expect(response).to have_http_status(:ok)
        expect(model.exists?(record.id)).to be(false)
      end

      it "serves new and edit shells" do
        record = build_record(model, valid_attributes)

        get new_path_for(segment)
        expect(response).to have_http_status(:ok)

        get edit_path_for(segment, record.id)
        expect(response).to have_http_status(:ok)
      end

      it "scopes to the current company" do
        other = create(:company)
        foreign = if model == CalendarProcedure
          other_position = other.calendar_positions.create!(name: "Foreign position", color: "#6366f1")
          other.calendar_procedures.create!(valid_attributes.merge(calendar_position_id: other_position.id))
        else
          other.public_send(model.name.tableize).create!(valid_attributes)
        end

        get member_path_for(segment, foreign.id), as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "CalendarPractitioner (needs a real Employee source)" do
    let!(:position) { create(:calendar_position, company: company) }
    let(:employee) { create(:employee, company: company) }
    let(:valid) { { name: "Dr. D", source_type: "Employee", source_id: employee.id, calendar_position_id: position.id } }

    it "creates a practitioner bridged to an employee" do
      post company_calendar_practitioners_path(company), params: { calendar_practitioner: valid }, as: :json

      expect(response).to have_http_status(:ok)
      expect(CalendarPractitioner.find_by(name: "Dr. D").source_type).to eq("Employee")
    end

    it "rejects a source_type outside SOURCE_TYPES" do
      post company_calendar_practitioners_path(company),
        params: { calendar_practitioner: valid.merge(source_type: "Spaceship") }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("Source type")
    end

    it "rejects a source_id that points at no record" do
      post company_calendar_practitioners_path(company),
        params: { calendar_practitioner: valid.merge(source_id: SecureRandom.uuid) }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)["errors"].join).to include("Source must reference")
    end

    it "filters by position" do
      other_position = create(:calendar_position, company: company)
      create(:calendar_practitioner, company: company, calendar_position: position, employee: employee)
      create(:calendar_practitioner, company: company, calendar_position: other_position)

      get company_calendar_practitioners_path(company, calendar_position_id: position.id), as: :json

      expect(JSON.parse(response.body)["calendar_practitioners"].size).to eq(1)
    end
  end
end
