# This service seeds the database with Project records. Each project is
# associated with a ProjectGroup and a Company.

class Seed::ProjectService
  def self.create(
    project_group: ProjectGroup.all.sample,
    name: nil,
    description: nil,
    code: nil,
    status: Project.statuses.keys.sample,
    business_type: Project.business_types.keys.sample,
    discarded_at: nil
  )
    raise "Cannot create a project: No project groups exist." if project_group.nil?
    company = project_group.company

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil
    name ||= "#{Faker::App.name} Project"
    description ||= "Project for group '#{project_group.name}'."
    code ||= "PROJ-#{branch.id}-#{project_group.id}-#{SecureRandom.hex(2).upcase}"

    Project.create!(
      branch: branch,
      project_group: project_group,
      name: name,
      description: description,
      code: code,
      status: status,
      business_type: business_type,
      discarded_at: discarded_at
    )
  end
end
