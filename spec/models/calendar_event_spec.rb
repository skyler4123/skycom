# frozen_string_literal: true

require "rails_helper"

RSpec.describe CalendarEvent, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to belong_to(:calendar_procedure) }
  it { is_expected.to belong_to(:branch).optional }
  it { is_expected.to have_many(:calendar_event_practitioners).dependent(:destroy) }
  it { is_expected.to have_many(:calendar_event_locations).dependent(:destroy) }
  it { is_expected.to have_many(:calendar_event_equipment).dependent(:destroy) }
  it { is_expected.to have_many(:calendar_event_participants).dependent(:destroy) }
  it { is_expected.to have_many(:calendar_practitioners).through(:calendar_event_practitioners) }

  describe "validations" do
    # An explicit company is required: the cross-company guard compares
    # procedure.company_id against event.company_id, which is nil until the
    # lazy association is read.
    subject(:event) { build(:calendar_event, company: create(:company)) }

    it { is_expected.to be_valid }

    it "requires a start and an end" do
      event.starts_at = nil
      event.ends_at = nil
      expect(event).not_to be_valid
    end

    it "rejects an end at or before the start" do
      event.ends_at = event.starts_at
      expect(event).not_to be_valid
      expect(event.errors[:ends_at].join).to include("after the start")
    end

    it "rejects a procedure from another company" do
      event.calendar_procedure = create(:calendar_procedure, company: create(:company))
      expect(event).not_to be_valid
      expect(event.errors[:calendar_procedure].join).to include("same company")
    end

    it "rejects a title longer than 255 characters" do
      event.title = "a" * 256
      expect(event).not_to be_valid
    end
  end

  describe "status helpers" do
    subject(:event) { create(:calendar_event) }

    it "defaults to pending" do
      expect(event.status).to eq("pending")
    end

    it "confirms and stamps confirmed_at" do
      event.confirm!
      expect(event.reload.status).to eq("confirmed")
      expect(event.confirmed_at).to be_present
    end

    it "cancels with a reason and stamps cancelled_at" do
      event.cancel!("no show")
      expect(event.reload.status).to eq("cancelled")
      expect(event.cancellation_reason).to eq("no show")
      expect(event.cancelled_at).to be_present
    end

    it "clears the cancellation when re-confirmed" do
      event.cancel!("x")
      event.confirm!
      expect(event.reload.cancellation_reason).to be_nil
      expect(event.cancelled_at).to be_nil
    end

    it "treats pending, confirmed and in_progress as blocking" do
      expect(event.blocking?).to be(true)
      event.status = :cancelled
      expect(event.blocking?).to be(false)
    end
  end

  describe "#to_calendar_payload" do
    it "emits the field names the calendar widget consumes" do
      event = create(:calendar_event, title: "Cleaning", all_day: false, status: :confirmed)
      payload = event.to_calendar_payload

      expect(payload).to include(:id, :title, :start, :end, :allDay, :backgroundColor, :extendedProps)
      expect(payload[:title]).to eq("Cleaning")
      expect(payload[:extendedProps][:status]).to eq("confirmed")
    end

    it "falls back to the procedure name when there is no title" do
      event = create(:calendar_event, title: nil)
      expect(event.to_calendar_payload[:title]).to eq(event.calendar_procedure.name)
    end

    it "marks a cancelled booking as not editable" do
      event = create(:calendar_event, status: :cancelled)
      expect(event.to_calendar_payload[:editable]).to be(false)
    end
  end

  describe ".overlapping" do
    let(:company) { create(:company) }
    let(:procedure) { create(:calendar_procedure, company: company) }
    let(:base) { Time.current.change(sec: 0, usec: 0) }

    def event_at(start_offset, duration)
      create(:calendar_event, company: company, calendar_procedure: procedure,
        starts_at: base + start_offset, ends_at: base + start_offset + duration)
    end

    it "includes events that partially overlap" do
      target = event_at(1.hour, 60.minutes) # 01:00–02:00
      overlapping = event_at(90.minutes, 60.minutes) # 01:30–02:30
      event_at(5.hours, 60.minutes)

      ids = described_class.overlapping(base + 30.minutes, base + 3.hours).pluck(:id)
      expect(ids).to include(target.id, overlapping.id)
    end

    it "treats shared endpoints as NOT overlapping" do
      first = event_at(1.hour, 60.minutes)  # 01:00–02:00
      second = event_at(2.hours, 60.minutes) # 02:00–03:00

      ids = described_class.overlapping(first.starts_at, first.ends_at).pluck(:id)
      expect(ids).to include(first.id)
      expect(ids).not_to include(second.id)
    end

    it "excludes events that end before the window opens" do
      event_at(0, 30.minutes)
      overlapping = event_at(1.hour, 60.minutes)

      ids = described_class.overlapping(base + 45.minutes, base + 3.hours).pluck(:id)
      expect(ids).to eq([ overlapping.id ])
    end
  end

  describe "#practitioner_ids readers" do
    it "falls back to the persisted join rows" do
      event = create(:calendar_event)
      practitioner = create(:calendar_practitioner, company: event.company)
      create(:calendar_event_practitioner, calendar_event: event, calendar_practitioner: practitioner, company: event.company)

      expect(event.practitioner_ids).to eq([ practitioner.id ])
    end

    it "prefers a pending assignment set when one was assigned" do
      event = build(:calendar_event)
      event.practitioner_ids = [ "abc" ]

      expect(event.practitioner_ids).to eq([ "abc" ])
    end
  end
end
