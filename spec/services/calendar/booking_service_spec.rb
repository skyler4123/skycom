# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar::BookingService, type: :service do
  let(:company) { create(:company) }
  let(:procedure) { create(:calendar_procedure, company: company) }
  let(:practitioner) { create(:calendar_practitioner, company: company) }
  let(:other_practitioner) { create(:calendar_practitioner, company: company) }
  let(:location) { create(:calendar_location, company: company) }
  let(:equipment) { create(:calendar_equipment, company: company) }
  let(:participant) { create(:calendar_participant, company: company) }
  let(:base) { Time.current.change(sec: 0, usec: 0) + 1.day }

  def attributes(**overrides)
    { calendar_procedure_id: procedure.id, title: "Extraction",
      starts_at: base, ends_at: base + 60.minutes, status: "confirmed" }.merge(overrides)
  end

  describe ".create" do
    it "persists the event and every assignment set atomically" do
      event = described_class.create(
        company: company, attributes: attributes,
        practitioner_ids: [ practitioner.id, other_practitioner.id ],
        location_ids: [ location.id ],
        equipment_ids: [ equipment.id ],
        participant_ids: [ participant.id ]
      )

      expect(event).to be_persisted
      expect(event.calendar_event_practitioners.count).to eq(2)
      expect(event.calendar_event_locations.count).to eq(1)
      expect(event.calendar_event_equipment.count).to eq(1)
      expect(event.calendar_event_participants.count).to eq(1)
    end

    it "gives the first pick the lead role and the rest the fallback" do
      event = described_class.create(
        company: company, attributes: attributes,
        practitioner_ids: [ practitioner.id, other_practitioner.id ]
      )

      roles = event.calendar_event_practitioners.order(:created_at).pluck(:role)
      expect(roles).to eq(%w[lead assistant])
    end

    it "deduplicates repeated ids" do
      event = described_class.create(
        company: company, attributes: attributes,
        practitioner_ids: [ practitioner.id, practitioner.id ]
      )

      expect(event.calendar_event_practitioners.count).to eq(1)
    end

    it "ignores blank ids" do
      event = described_class.create(
        company: company, attributes: attributes, practitioner_ids: [ practitioner.id, nil, "" ]
      )

      expect(event.calendar_event_practitioners.count).to eq(1)
    end

    it "raises Conflict for a double-booked resource" do
      described_class.create(company: company, attributes: attributes, location_ids: [ location.id ])

      expect {
        described_class.create(company: company, attributes: attributes, location_ids: [ location.id ])
      }.to raise_error(Calendar::BookingService::Conflict, /already booked/)
    end

    it "raises Error (not Conflict) for a plain validation failure" do
      expect {
        described_class.create(company: company, attributes: attributes(ends_at: base - 1.hour))
      }.to raise_error(Calendar::BookingService::Error) { |error|
        expect(error).not_to be_a(Calendar::BookingService::Conflict)
        expect(error.messages.join).to include("after the start")
      }
    end

    it "writes nothing when the save is rejected" do
      # Seed the clash first, outside the block, so the measured count is the
      # count before the *rejected* attempt.
      described_class.create(company: company, attributes: attributes, location_ids: [ location.id ])

      expect {
        expect {
          described_class.create(company: company, attributes: attributes, location_ids: [ location.id ])
        }.to raise_error(Calendar::BookingService::Conflict)
      }.not_to change(CalendarEvent, :count)
    end

    it "rolls back the join rows too when the event save is rejected" do
      described_class.create(company: company, attributes: attributes, location_ids: [ location.id ])

      expect {
        expect {
          described_class.create(company: company, attributes: attributes,
            practitioner_ids: [ practitioner.id ], location_ids: [ location.id ])
        }.to raise_error(Calendar::BookingService::Conflict)
      }.not_to change(CalendarEventPractitioner, :count)
    end

    it "works with no assignments at all" do
      event = described_class.create(company: company, attributes: attributes)

      expect(event).to be_persisted
      expect(event.calendar_event_practitioners).to be_empty
    end
  end

  describe ".update" do
    let!(:event) do
      described_class.create(company: company, attributes: attributes,
        practitioner_ids: [ practitioner.id ], location_ids: [ location.id ])
    end

    it "replaces the assignment set it is given" do
      described_class.update(calendar_event: event, attributes: {},
        practitioner_ids: [ other_practitioner.id ])

      event.reload
      expect(event.calendar_practitioners.pluck(:id)).to eq([ other_practitioner.id ])
    end

    it "clears an assignment set when given an empty list" do
      described_class.update(calendar_event: event, attributes: {},
        practitioner_ids: [ other_practitioner.id ], location_ids: [])

      event.reload
      expect(event.calendar_practitioners.pluck(:id)).to eq([ other_practitioner.id ])
      expect(event.calendar_event_locations).to be_empty
    end

    it "leaves an assignment set untouched when nil is passed" do
      described_class.update(calendar_event: event, attributes: { title: "Renamed" })

      expect(event.reload.calendar_locations.count).to eq(1)
      expect(event.title).to eq("Renamed")
    end

    it "rejects a move that collides with another booking" do
      other = described_class.create(company: company,
        attributes: attributes(starts_at: base + 5.hours, ends_at: base + 6.hours),
        location_ids: [ location.id ])

      expect {
        described_class.update(calendar_event: event, attributes: attributes(starts_at: base + 5.hours, ends_at: base + 6.hours))
      }.to raise_error(Calendar::BookingService::Conflict)
      expect(other.reload).to be_present
    end
  end

  describe ".preview_conflicts" do
    before do
      described_class.create(company: company, attributes: attributes, location_ids: [ location.id ])
    end

    it "reports the clash without writing" do
      expect {
        described_class.preview_conflicts(company: company, attributes: attributes, location_ids: [ location.id ])
      }.not_to change(CalendarEvent, :count)

      conflicts = described_class.preview_conflicts(company: company, attributes: attributes, location_ids: [ location.id ])
      expect(conflicts.first[:message]).to include("already booked")
    end

    it "reports nothing for a free slot" do
      conflicts = described_class.preview_conflicts(company: company,
        attributes: attributes(starts_at: base + 8.hours, ends_at: base + 9.hours),
        location_ids: [ location.id ])

      expect(conflicts).to be_empty
    end
  end
end
