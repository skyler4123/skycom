class Seed::EventService
  def self.create(
    company:,
    branch: nil,
    event_group: nil,
    name: nil,
    description: nil,
    code: nil,
    start_at: nil,
    end_at: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    event_group ||= EventGroup.create!(company: company, branch: branch) if company
    branch ||= event_group.branch if event_group
    company ||= event_group.company if event_group

    Event.create!(
      company: company,
      branch: branch,
      event_group: event_group,
      name: name || "Event #{Faker::Lorem.sentence(word_count: 3)}",
      description: description || Faker::Lorem.sentence(word_count: 10),
      code: code || "EVT-#{SecureRandom.hex(4).upcase}",
      start_at: start_at || Faker::Time.forward(days: 30),
      end_at: end_at || Faker::Time.forward(days: 60),
      status: status || Event.statuses.keys.sample,
      business_type: business_type || Event.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
