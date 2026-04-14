class Seed::ProjectService
  def self.create(
    company:,
    branch: nil,
    project_group: nil,
    name: nil,
    description: nil,
    code: nil,
    status: nil,
    business_type: nil,
    discarded_at: nil
  )
    raise "Cannot create a project: No project_group provided." if project_group.nil? && branch.nil?

    branch ||= project_group.branch if project_group
    company ||= branch&.company || project_group&.company

    should_discard = rand(10) == 0
    discarded_at ||= should_discard ? Time.zone.now - rand(1..180).days : nil

    Project.create!(
      branch: branch,
      project_group: project_group,
      company: company,
      name: name || "#{Faker::App.name} Project",
      description: description || (project_group ? "Project for group '#{project_group.name}'." : nil),
      code: code || "PROJ-#{branch.id}-#{project_group.id}-#{SecureRandom.hex(2).upcase}",
      status: status || Project.statuses.keys.sample,
      business_type: business_type || Project.business_types.keys.sample,
      discarded_at: discarded_at
    )
  end
end
