class Seed::ScheduledShiftService
  # Idempotent upsert keyed on the globally-unique (employee, work_date) pair.
  # The dev check-in simulator (Attendance::CheckInSimulatorJob, every second)
  # can create today's row concurrently with seeding — a bare create! then
  # raises PG::UniqueViolation. Last-writer-wins keeps seed data deterministic.
  def self.upsert!(company:, branch:, employee:, shift_template:, work_date:,
                   expected_start_at:, expected_end_at:, status: :scheduled)
    attributes = {
      company: company, branch: branch, shift_template: shift_template,
      expected_start_at: expected_start_at, expected_end_at: expected_end_at,
      status: status
    }

    shift = ScheduledShift.find_or_initialize_by(employee: employee, work_date: work_date)
    shift.assign_attributes(attributes)
    begin
      shift.save!
    rescue ActiveRecord::RecordNotUnique
      # Lost the insert race — apply our attributes onto the winner instead.
      shift = ScheduledShift.find_by!(employee: employee, work_date: work_date)
      shift.update!(attributes)
    end
    shift
  end
end
