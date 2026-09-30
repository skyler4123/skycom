# spec: docs/CALENDAR.md §9 — builds the Calendar/Schedule demo dataset.
#
# The scenario is the dental clinic from the design conversation:
#
#   Position        Dentist, Dental Assistant
#   Practitioners    2 dentists + 2 assistants, each bridged to a real Employee
#   Locations       2 surgery rooms (bridged to Facility)
#   Equipment       X-ray + autoclave (bridged to Stock)
#   Participants    patients (bridged to Customer)
#   Procedures      Tooth Extraction (needs room + machine), Cleaning, Consultation
#   Availability    Mon–Fri 09:00–17:00 per practitioner, Sat morning for room 1
#   Events          ~40 bookings across ±2 months
#
# BOOKINGS ARE DELIBERATELY NON-OVERLAPPING PER RESOURCE. The hard-block
# conflict validation has no seed bypass (Seed::CalendarEventService goes through
# Calendar::BookingService), so a naive "random time for everyone" seeder would
# raise InvalidRecord partway through and leave a half-built dataset. Slots are
# therefore handed out so that no practitioner, room or machine is ever in two
# places at once.
class Seed::CalendarEnrichService
  POSITIONS = [
    { name: "Dentist", color: "#6366f1", default_duration_minutes: 60, sort_order: 0 },
    { name: "Dental Assistant", color: "#0ea5e9", default_duration_minutes: 45, sort_order: 1 }
  ].freeze

  LOCATIONS = [
    { name: "Surgery Room 1", color: "#0ea5e9", capacity: 1 },
    { name: "Surgery Room 2", color: "#38bdf8", capacity: 1 }
  ].freeze

  EQUIPMENT = [
    { name: "Dental X-Ray Machine", color: "#f59e0b", quantity: 1 },
    { name: "Autoclave Sterilizer", color: "#fbbf24", quantity: 1 }
  ].freeze

  PROCEDURES = [
    { name: "Tooth Extraction", duration_minutes: 60, color: "#ef4444",
      requires_location: true, requires_equipment: true, requires_practitioners: 2 },
    { name: "Dental Cleaning", duration_minutes: 45, color: "#10b981",
      requires_location: true, requires_equipment: false, requires_practitioners: 1 },
    { name: "Consultation", duration_minutes: 30, color: "#6366f1",
      requires_location: false, requires_equipment: false, requires_practitioners: 1 }
  ].freeze

  WEEKDAYS = [ 1, 2, 3, 4, 5 ].freeze
  PAST_MONTHS = 2
  FUTURE_WEEKS = 6
  CLINIC_START_HOUR = 9
  CLINIC_END_HOUR = 17
  SLOT_MINUTES = 15

  def initialize(company:, employees: [], patients: [], facilities: [], stocks: [], seed_patients: 8)
    @company = company
    @employees = employees
    @patients = patients
    @facilities = facilities
    @stocks = stocks
    @seed_patients = seed_patients
    seeding
  end

  def seeding
    puts "  Seeding Calendar/Schedule data..."

    create_positions
    create_locations
    create_equipment
    create_participants
    create_practitioners
    create_procedures
    create_availability
    create_events
  end

  private

  attr_reader :company, :employees, :patients, :facilities, :stocks

  # Employees are named "Employee N" by the enrich services — the job title
  # lives on the Role association, so match on that, not on the name.
  def dentists
    @dentists ||= employees_with_role("Dentist")
  end

  def assistants
    @assistants ||= employees_with_role("DentalAssistant")
  end

  # Queries the appointment table directly rather than the `roles` association:
  # RoleConcern#attach_role documents that `roles` can be memoised and miss rows
  # created moments earlier, which is exactly the state the enrich services leave
  # behind.
  def employees_with_role(role_name)
    role = company.roles.find_by(name: role_name)
    return [] if role.blank?

    matched = EmployeeRoleAppointment
      .where(company_id: company.id, role_id: role.id)
      .pluck(:employee_id)
    employees.select { |e| matched.include?(e.id) }
  end

  # A practitioner needs a position; a company with no employees gets none rather
  # than a row with an unresolvable source link.
  def create_positions
    @dentist_position = Seed::CalendarPositionService.create(company: company, **POSITIONS[0])
    @assistant_position = Seed::CalendarPositionService.create(company: company, **POSITIONS[1])
  end

  def create_locations
    @locations = LOCATIONS.each_with_index.map do |attrs, index|
      Seed::CalendarLocationService.create(
        company: company, branch: company.branches.first, facility: facilities[index], **attrs
      )
    end
  end

  def create_equipment
    @equipment = EQUIPMENT.each_with_index.map do |attrs, index|
      Seed::CalendarEquipmentService.create(company: company, stock: stocks[index], **attrs)
    end
  end

  def create_participants
    @participants = Array.new(@seed_patients) do |index|
      Seed::CalendarParticipantService.create(
        company: company, customer: patients[index % patients.size]
      )
    end
  end

  def create_practitioners
    @dentist_practitioners = build_practitioners(dentists, @dentist_position, 2)
    @assistant_practitioners = build_practitioners(assistants, @assistant_position, 2)
    @all_practitioners = @dentist_practitioners + @assistant_practitioners
  end

  def build_practitioners(pool, position, count)
    return [] if pool.blank?

    pool.first(count).map do |employee|
      Seed::CalendarPractitionerService.create(
        company: company, calendar_position: position, employee: employee
      )
    end
  end

  def create_procedures
    @procedures = PROCEDURES.map do |attrs|
      position = attrs[:requires_practitioners] > 1 ? @dentist_position : @dentist_position
      Seed::CalendarProcedureService.create(company: company, calendar_position: position, **attrs)
    end
  end

  def create_availability
    @all_practitioners.each do |practitioner|
      Seed::CalendarAvailabilityRuleService.create(
        company: company, calendar_practitioner: practitioner,
        name: "Weekday clinic", days_of_week: WEEKDAYS,
        start_time: "09:00", end_time: "17:00"
      )
    end

    # Room 1 also opens on Saturday mornings.
    if @locations.first
      Seed::CalendarAvailabilityRuleService.create(
        company: company, calendar_location: @locations.first,
        name: "Saturday surgery", days_of_week: [ 6 ],
        start_time: "09:00", end_time: "13:00"
      )
    end
  end

  # Slot handout. Each 15-minute slot index is allocated to exactly one
  # practitioner, one room and one machine, so a booking in that slot can never
  # collide with another.
  def create_events
    return if @all_practitioners.blank? || @participants.blank? || @procedures.blank?

    practitioners = @all_practitioners
    rooms = @locations.presence || [ nil ]
    machines = @equipment.presence || [ nil ]
    slot = 0

    each_business_day do |day|
      # 09:00–11:00, 11:30–13:00, 14:00–16:00 => 3 bookings per day.
      3.times do
        procedure = @procedures[slot % @procedures.size]
        practitioner = practitioners[slot % practitioners.size]
        assistant = @dentist_practitioners.include?(practitioner) ? @assistant_practitioners[slot % [ @assistant_practitioners.size, 1 ].max] : nil

        Seed::CalendarEventService.create(
          company: company,
          calendar_procedure: procedure,
          # The procedure's own declared requirement decides what it consumes.
          practitioner_ids: [ practitioner, assistant ].compact.map(&:id),
          location_ids: procedure.requires_location && rooms[slot % rooms.size] ? [ rooms[slot % rooms.size].id ] : [],
          equipment_ids: procedure.requires_equipment && machines[slot % machines.size] ? [ machines[slot % machines.size].id ] : [],
          participant_ids: [ @participants[slot % @participants.size].id ],
          starts_at: slot_time(day, slot),
          status: day < Date.current ? :completed : :confirmed
        )

        slot += 1
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    # Should be unreachable — slot handout guarantees no overlap — but a partial
    # dataset is worse than a loud failure mid-seed.
    raise "CalendarEnrichService produced an invalid booking: #{e.record&.errors&.full_messages&.to_sentence}"
  end

  # 09:00, 11:30, 14:00 — spread so back-to-back windows never touch.
  def slot_time(day, index)
    offsets = [ 0, 2.5, 5 ].freeze
    base = Time.zone.parse(day.to_s).change(hour: CLINIC_START_HOUR, min: 0, sec: 0)
    base + offsets[index % offsets.size].hours
  end

  def each_business_day
    from = Date.current - PAST_MONTHS.months
    to = Date.current + FUTURE_WEEKS.weeks

    (from..to).each do |day|
      next unless WEEKDAYS.include?(day.wday)

      yield day
    end
  end
end
