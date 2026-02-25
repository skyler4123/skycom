# This service seeds the database with ProjectGroup records. Each group is
# associated with a Company and can be used to organize projects.

class Seed::ProjectGroupService
  def self.create(
    branch:,
    name: "#{Faker::App.name} Project Group",
    description: "A group for projects related to #{Faker::Commerce.department}.",
    code: nil,
    status: ProjectGroup.statuses.keys.sample,
    business_type: ProjectGroup.business_types.keys.sample,
    discarded_at: nil
  )
    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    code ||= "PROJ-G-#{branch.id}-#{SecureRandom.hex(3).upcase}"

    ProjectGroup.create!(
      branch: branch,
      name: name,
      description: description,
      code: code,
      status: status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
