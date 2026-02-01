class DemoController < ApplicationController
  def index
  end

  def calendar_events
    # Get the requested range from params (fallback to current month)
    start_date = params[:start]&.to_date || Date.current.beginning_of_month
    end_date   = params[:end]&.to_date   || Date.current.end_of_month

    # For testing: force events into THIS WEEK only
    # (Monday → Sunday of the current week)
    today = Date.current
    week_start = today.beginning_of_week(:monday)
    week_end   = today.end_of_week(:sunday)

    # We'll generate events only inside this week
    events = []

    # Sample titles & colors
    titles_and_colors = [
      { title: "Daily Standup",           color: "#3b82f6", all_day: false },
      { title: "Code Review",              color: "#6366f1", all_day: false },
      { title: "Client Meeting",           color: "#2563eb", all_day: false },
      { title: "Gym Session",              color: "#10b981", all_day: false },
      { title: "Team Lunch",               color: "#f59e0b", all_day: false },
      { title: "Doctor Appointment",       color: "#ef4444", all_day: true  },
      { title: "Project Planning",         color: "#8b5cf6", all_day: false },
      { title: "Weekend Hiking",           color: "#f97316", all_day: true  },
      { title: "Family Dinner",            color: "#ec4899", all_day: false },
      { title: "Public Holiday (mock)",    color: "#f87171", all_day: true  }
    ]

    # Generate ~10–15 events spread across the current week
    (0..14).each do |i|
      # Pick random day in the current week
      day_offset = rand(0..6)
      event_date = week_start + day_offset.days

      # Pick random sample
      sample = titles_and_colors.sample

      # Random start hour (9–18) for non-all-day events
      start_hour = rand(9..17)
      start_time = event_date.to_time + start_hour.hours + rand(0..50).minutes

      # Duration: 30min to 3 hours
      duration_minutes = [30, 45, 60, 90, 120, 180].sample

      event = {
        id: "evt-#{1000 + i}",
        title: sample[:title],
        backgroundColor: sample[:color],
        borderColor: sample[:color],
        textColor: "#ffffff",
        allDay: sample[:all_day],
        extendedProps: {
          department: ["Engineering", "Design", "Product", "Marketing"].sample,
          participants: ["@SkylerPTP", "@alice_dev", "@bob_pm", "@jane"].sample(2 + rand(0..2)),
          priority: ["low", "medium", "high"].sample,
          status: ["confirmed", "tentative", "cancelled"].sample
        }
      }

      if sample[:all_day]
        # All-day event → use date only (no time)
        event[:start] = event_date.iso8601
        # Optional: multi-day all-day event (sometimes)
        if rand < 0.2
          event[:end] = (event_date + rand(1..2).days).iso8601
        end
      else
        # Timed event
        event[:start] = start_time.iso8601
        event[:end]   = (start_time + duration_minutes.minutes).iso8601
      end

      events << event
    end

    # Optional: always add one multi-day holiday-like event
    events << {
      id: "evt-holiday-001",
      title: "Mock Holiday Period",
      start: week_start.iso8601,
      end: (week_start + 2.days).iso8601,
      backgroundColor: "#f87171",
      allDay: true
    }

    render json: events
  end
end
