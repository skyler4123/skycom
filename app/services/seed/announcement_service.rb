# frozen_string_literal: true

# Seed-only company announcement: one published Document linked to every
# employee so mobile Home can render a real company notice.
class Seed::AnnouncementService
  TITLE = "Payroll, leave, and notices are live on mobile"
  DESCRIPTION = "Review payroll, check your paid-leave balance, and read company notices from the mobile app."
  BODY_MARKDOWN = <<~MARKDOWN
    # Mobile update

    You can now review **payroll**, check your **paid-leave balance**, and read
    **company notices** from the mobile app.

    Contact your manager if something looks wrong.
  MARKDOWN

  def self.create_samples!(company:)
    new(company: company).call
  end

  def initialize(company:)
    @company = company
  end

  def call
    document = @company.documents.announcements.find_or_initialize_by(name: TITLE)
    document.assign_attributes(
      company: @company,
      description: DESCRIPTION,
      body_markdown: BODY_MARKDOWN,
      business_type: :announcement,
      workflow_status: :published,
      lifecycle_status: :active
    )
    document.category ||= Seed::CategoryService.find_or_create_for(company: @company, resource_name: "documents")
    document.property_mapping ||= document.category.default_property_mapping
    Seed::PropertyPopulator.populate(document)
    document.save! if document.changed?

    @company.employees.find_each do |employee|
      DocumentEmployeeAppointment.find_or_create_by!(company: @company, document: document, employee: employee)
    end

    document
  end
end
