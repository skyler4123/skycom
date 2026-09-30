# spec: docs/CALENDAR.md — a bookable appointment type ("Removal teeth").
class Seed::CalendarProcedureService
  def self.new(
    company: nil,
    calendar_position: nil,
    branch: nil,
    service: nil,
    name: nil,
    code: nil,
    slug: nil,
    description: nil,
    duration_minutes: 30,
    buffer_before_minutes: 0,
    buffer_after_minutes: 0,
    min_lead_minutes: 0,
    color: "#6366f1",
    requires_location: false,
    requires_equipment: false,
    requires_practitioners: 1
  )
    base = name || service&.name || "Procedure"
    CalendarProcedure.new(
      company: company || service&.company,
      calendar_position: calendar_position,
      branch: branch,
      source_type: service ? "Service" : nil,
      source_id: service&.id,
      name: base,
      code: code,
      # slug is unique per company; derive a stable one from the name.
      slug: slug || base.to_s.parameterize.presence || "procedure",
      description: description || service&.description,
      duration_minutes: duration_minutes,
      buffer_before_minutes: buffer_before_minutes,
      buffer_after_minutes: buffer_after_minutes,
      min_lead_minutes: min_lead_minutes,
      color: color,
      requires_location: requires_location,
      requires_equipment: requires_equipment,
      requires_practitioners: requires_practitioners,
      lifecycle_status: :active
    )
  end

  def self.create(...)
    procedure = new(...)
    procedure.slug = "#{procedure.slug}-#{SecureRandom.hex(2)}" if procedure.slug.present? &&
      CalendarProcedure.where(company: procedure.company_id, slug: procedure.slug).exists?
    procedure.save!
    procedure
  end
end
