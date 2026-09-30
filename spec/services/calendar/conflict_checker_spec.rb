# frozen_string_literal: true

require "rails_helper"

RSpec.describe Calendar::ConflictChecker, type: :service do
  let(:company) { create(:company) }
  let(:procedure) { create(:calendar_procedure, company: company) }
  let(:practitioner) { create(:calendar_practitioner, company: company) }
  let(:other_practitioner) { create(:calendar_practitioner, company: company) }
  let(:location) { create(:calendar_location, company: company) }
  let(:equipment) { create(:calendar_equipment, company: company) }
  let(:participant) { create(:calendar_participant, company: company) }
  let(:base) { Time.current.change(sec: 0, usec: 0) + 1.day }

  def existing(assigns = {})
    event = create(:calendar_event, company: company, calendar_procedure: procedure,
      starts_at: base, ends_at: base + 60.minutes, status: :confirmed)
    assigns.each do |kind, record|
      case kind
      when :practitioner then create(:calendar_event_practitioner, calendar_event: event, calendar_practitioner: record, company: company)
      when :location then create(:calendar_event_location, calendar_event: event, calendar_location: record, company: company)
      when :equipment then create(:calendar_event_equipment, calendar_event: event, calendar_equipment: record, company: company)
      when :participant then create(:calendar_event_participant, calendar_event: event, calendar_participant: record, company: company)
      end
    end
    event
  end

  def candidate(**attrs)
    event = build(:calendar_event, company: company, calendar_procedure: procedure, **attrs)
    described_class.new(event)
  end

  describe "no conflict" do
    it "returns nothing when no resources are assigned" do
      expect(candidate(starts_at: base, ends_at: base + 60.minutes).conflicts).to be_empty
    end

    it "returns nothing for a free practitioner" do
      expect(candidate(starts_at: base, ends_at: base + 60.minutes).tap { |c|
        c.event.practitioner_ids = [ practitioner.id ]
      }.conflicts).to be_empty
    end

    it "allows two practitioners at the same time" do
      existing(practitioner: practitioner)

      checker = candidate(starts_at: base, ends_at: base + 60.minutes)
      checker.event.practitioner_ids = [ other_practitioner.id ]

      expect(checker.conflicts).to be_empty
    end

    it "allows a back-to-back booking (shared endpoint is not an overlap)" do
      existing(practitioner: practitioner)

      checker = candidate(starts_at: base + 60.minutes, ends_at: base + 120.minutes)
      checker.event.practitioner_ids = [ practitioner.id ]

      expect(checker.conflicts).to be_empty
    end

    it "ignores a cancelled booking" do
      existing(practitioner: practitioner).cancel!

      checker = candidate(starts_at: base, ends_at: base + 60.minutes)
      checker.event.practitioner_ids = [ practitioner.id ]

      expect(checker.conflicts).to be_empty
    end

    it "ignores a no-show booking" do
      event = existing(practitioner: practitioner)
      event.update!(status: :no_show)

      checker = candidate(starts_at: base, ends_at: base + 60.minutes)
      checker.event.practitioner_ids = [ practitioner.id ]

      expect(checker.conflicts).to be_empty
    end
  end

  describe "conflicts" do
    it "flags a double-booked practitioner" do
      existing(practitioner: practitioner)

      checker = candidate(starts_at: base + 30.minutes, ends_at: base + 90.minutes)
      checker.event.practitioner_ids = [ practitioner.id ]

      conflict = checker.conflicts.first
      expect(conflict[:kind]).to eq(:practitioner)
      expect(conflict[:resource_name]).to eq(practitioner.name)
      expect(conflict[:message]).to include("already booked")
    end

    it "flags a double-booked room even with a different practitioner" do
      existing(location: location)

      checker = candidate(starts_at: base + 30.minutes, ends_at: base + 90.minutes)
      checker.event.location_ids = [ location.id ]

      expect(checker.conflicts.first[:kind]).to eq(:location)
    end

    it "flags a double-booked machine" do
      existing(equipment: equipment)

      checker = candidate(starts_at: base + 30.minutes, ends_at: base + 90.minutes)
      checker.event.equipment_ids = [ equipment.id ]

      expect(checker.conflicts.first[:kind]).to eq(:equipment)
    end

    it "flags a double-booked participant" do
      existing(participant: participant)

      checker = candidate(starts_at: base + 30.minutes, ends_at: base + 90.minutes)
      checker.event.participant_ids = [ participant.id ]

      expect(checker.conflicts.first[:kind]).to eq(:participant)
    end

    it "reports one conflict per resource, not per overlapping event" do
      2.times { |i| create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: base + i.minutes, ends_at: base + 60.minutes, status: :confirmed) }
      shared = create(:calendar_practitioner, company: company)
      CalendarEvent.where(company: company).find_each do |event|
        create(:calendar_event_practitioner, calendar_event: event, calendar_practitioner: shared, company: company)
      end

      checker = candidate(starts_at: base + 5.minutes, ends_at: base + 30.minutes)
      checker.event.practitioner_ids = [ shared.id ]

      expect(checker.conflicts.size).to eq(1)
    end

    it "returns several conflicts when several resources clash" do
      existing(practitioner: practitioner, location: location)

      checker = candidate(starts_at: base + 30.minutes, ends_at: base + 90.minutes)
      checker.event.practitioner_ids = [ practitioner.id ]
      checker.event.location_ids = [ location.id ]

      expect(checker.conflicts.map { |c| c[:kind] }).to match_array(%i[practitioner location])
    end

    it "does not see another company's bookings" do
      foreign_company = create(:company)
      foreign_practitioner = create(:calendar_practitioner, company: foreign_company)
      event = create(:calendar_event, company: foreign_company,
        calendar_procedure: create(:calendar_procedure, company: foreign_company),
        starts_at: base, ends_at: base + 60.minutes, status: :confirmed)
      create(:calendar_event_practitioner, calendar_event: event,
        calendar_practitioner: foreign_practitioner, company: foreign_company)

      checker = candidate(starts_at: base, ends_at: base + 60.minutes)
      checker.event.practitioner_ids = [ foreign_practitioner.id ]

      expect(checker.conflicts).to be_empty
    end
  end

  describe "guards" do
    it "returns nothing for an event that is not yet scheduled" do
      checker = described_class.new(build(:calendar_event, company: company))
      expect(checker.conflicts).to be_empty
    end

    it "returns nothing when the candidate is already cancelled" do
      existing(practitioner: practitioner)
      checker = candidate(starts_at: base, ends_at: base + 60.minutes, status: :cancelled)
      checker.event.practitioner_ids = [ practitioner.id ]

      expect(checker.conflicts).to be_empty
    end

    it "reports conflict? consistently with conflicts" do
      existing(practitioner: practitioner)
      checker = candidate(starts_at: base, ends_at: base + 60.minutes)
      checker.event.practitioner_ids = [ practitioner.id ]

      expect(checker.conflict?).to be(true)
    end
  end
end
