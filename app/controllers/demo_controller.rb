class DemoController < ApplicationController
  def index
  end

  def calendar_events
    # Get requested range (or fallback)
    start_date = params[:start]&.to_date || Date.current.beginning_of_month
    end_date   = params[:end]&.to_date   || Date.current.end_of_month

    # Demo window: last 2 months + next 3 months (so navigation shows data)
    demo_start = Date.current - 2.months
    demo_end   = Date.current + 3.months

    events = []

    # Realistic event templates
    event_templates = [
      { category: "work",     title_prefix: "Team ",     color: "#3b82f6", all_day_prob: 0.1 },
      { category: "work",     title_prefix: "Meeting with ", color: "#6366f1", all_day_prob: 0.2 },
      { category: "work",     title_prefix: "Review: ",  color: "#2563eb", all_day_prob: 0.05 },
      { category: "personal", title_prefix: "Gym - ",    color: "#10b981", all_day_prob: 0.05 },
      { category: "personal", title_prefix: "Doctor ",   color: "#ef4444", all_day_prob: 0.8 },
      { category: "personal", title_prefix: "Dinner with ", color: "#f59e0b", all_day_prob: 0.3 },
      { category: "personal", title_prefix: "Family ",   color: "#ec4899", all_day_prob: 0.4 },
      { category: "holiday",  title_prefix: "",          color: "#f87171", all_day_prob: 1.0 }
    ]

    events_per_month_target = 25..45

    (demo_start..demo_end).select { |d| d.day == 1 }.each do |month_start|
      month_end = month_start.end_of_month

      rand(events_per_month_target).times do
        event_date = Faker::Date.between(from: month_start, to: month_end)
        template   = event_templates.sample
        is_all_day = rand < template[:all_day_prob]

        event = {
          id:              "evt-#{SecureRandom.hex(6)}",
          title:           generate_title(template, event_date),
          backgroundColor: template[:color],
          borderColor:     template[:color],
          textColor:       "#ffffff",
          allDay:          is_all_day,
          extendedProps: {
            department:   Faker::Job.field,
            participants: Faker::Lorem.words(number: rand(2..5)).map { |w| "@#{w}" },
            priority:     %w[low medium high].sample,
            status:       %w[confirmed tentative cancelled].sample,
            category:     template[:category]
          }
        }

        if is_all_day
          event[:start] = event_date.iso8601
          event[:end]   = (event_date + rand(1..3).days).iso8601 if rand < 0.15
        else
          start_hour   = rand(8..19)
          start_minute = [ 0, 15, 30, 45 ].sample
          start_time   = event_date.to_time.change(hour: start_hour, min: start_minute)

          duration_min = [ 30, 45, 60, 90, 120, 150, 180, 210 ].sample

          event[:start] = start_time.iso8601
          event[:end]   = (start_time + duration_min.minutes).iso8601
        end

        events << event
      end
    end

    # Always include a visible multi-day holiday block near now
    events << {
      id: "evt-holiday-demo",
      title: "Lunar New Year Holiday (mock)",
      start: (Date.current - 3.days).iso8601,
      end:   (Date.current + 4.days).iso8601,
      backgroundColor: "#f87171",
      allDay: true
    }

    render json: events
  end

  private

  def generate_title(template, date)
    prefix = template[:title_prefix]

    case template[:category]
    when "work"
      [
        "#{prefix}#{Faker::Company.industry} Sync",
        "#{prefix}#{Faker::Job.position} Review",
        "#{Faker::Job.title} with #{Faker::Name.first_name}",
        "Sprint Planning – #{Faker::App.name}",
        "1:1 with #{Faker::Name.name}"
      ].sample
    when "personal"
      [
        "#{prefix}#{Faker::Hobby.activity}",
        "Dinner with #{Faker::Name.first_name}",
        "Gym - #{Faker::Team.creature} workout",
        "Doctor – #{Faker::Job.field}",                    # ← fixed: use real Faker method
        "Movie night: #{Faker::Movie.title}"
      ].sample
    when "holiday"
      [ "Public Holiday", "National Day", "Company Shutdown", "Festival" ].sample
    else
      "#{prefix}#{Faker::Lorem.words(number: 2..4).join(' ')}"
    end
  end
end
