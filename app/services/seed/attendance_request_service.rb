class Seed::AttendanceRequestService
  # Dev samples: one pending, one approved (with linked AttendanceDay), one
  # rejected. Dates sit outside the 14-day resolution window so the samples
  # never collide with resolution-engine days.
  SAMPLES = [
    { offset: 20, decision: :pending, business_type: :field_work, reason: "Client site visit — no office GPS" },
    { offset: 21, decision: :approved, business_type: :remote_work, reason: "Worked from home — VPN logs attached" },
    { offset: 22, decision: :rejected, business_type: :onsite_miss, reason: "Missed check-in — forgot phone", note: "No proof provided" }
  ].freeze

  def self.create_samples(company:, employees:)
    requesters = employees.select { |e| e.can?(:create, AttendanceRequest) }
    return 0 if requesters.empty?

    approver = company.employees.find_by(business_type: "owner")
    created = 0

    SAMPLES.each_with_index do |sample, i|
      employee = requesters[i % requesters.size]
      date = Date.current - sample[:offset].days
      next if AttendanceDay.exists?(company_id: company.id, employee_id: employee.id, attendance_date: date)

      request = AttendanceRequest.create!(
        company: company,
        branch: employee.branch,
        employee: employee,
        attendance_date: date,
        check_in: date.to_time.change(hour: 9),
        check_out: date.to_time.change(hour: 17),
        reason: sample[:reason],
        business_type: sample[:business_type]
      )
      created += 1

      case sample[:decision]
      when :approved
        next if approver.nil?
        AttendanceRequests::ApproveService.call(request: request, approver: approver)
      when :rejected
        next if approver.nil?
        AttendanceRequests::RejectService.call(request: request, approver: approver, note: sample[:note])
      end
    end

    created
  end
end
