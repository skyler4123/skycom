require 'rails_helper'

RSpec.describe CalendarEvent, type: :model do
  let(:company) { create(:company) }

  it "creates a valid event" do
    event = CalendarEvent.new(
      company: company,
      title: "ERP Setup Consultation",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 45.minutes
    )
    expect(event).to be_valid
  end

  it "requires title and times" do
    event = CalendarEvent.new(company: company)
    expect(event).not_to be_valid
    expect(event.errors[:title]).to be_present
  end

  it "rejects ends_at before starts_at" do
    event = CalendarEvent.new(
      company: company,
      title: "Bad",
      starts_at: 2.days.from_now,
      ends_at: 1.day.from_now
    )
    expect(event).not_to be_valid
    expect(event.errors[:ends_at]).to be_present
  end

  it "exposes attendees and meeting metadata via store_accessor" do
    event = CalendarEvent.new(
      company: company,
      title: "Call",
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 30.minutes,
      attendees: [ { "name" => "Client", "email" => "client@example.com" } ],
      meeting_url: "https://meet.example/x",
      location_type: "google_meet"
    )
    expect(event.attendees.first["email"]).to eq("client@example.com")
    expect(event.meeting_url).to eq("https://meet.example/x")
  end

  it "scopes upcoming ordered by starts_at" do
    past = CalendarEvent.create!(
      company: company, title: "Past",
      starts_at: 2.days.ago, ends_at: 2.days.ago + 30.minutes
    )
    future = CalendarEvent.create!(
      company: company, title: "Future",
      starts_at: 2.days.from_now, ends_at: 2.days.from_now + 30.minutes
    )
    expect(CalendarEvent.upcoming).to include(future)
    expect(CalendarEvent.upcoming).not_to include(past)
  end
end
