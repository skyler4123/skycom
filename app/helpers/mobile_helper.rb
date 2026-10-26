# frozen_string_literal: true

# Formatting and labelling helpers for the server-rendered /mobile pages.
# Preview values are the only hardcoded sample data in the mobile namespace;
# every view that uses one must render mobile_sample_badge next to it.
module MobileHelper
  PREVIEW = {
    paid_leave_days: "14 Days",
    paid_leave_pending: "3 Pending",
    notice_title: "Sample company notice",
    notice_body: "Placeholder content — replace with a real announcement feed.",
    supervisor: "Sample Manager",
    contract_renewal: "Nov 2026",
    payroll_net: "$4,862.50",
    payroll_gross: "$5,620.00",
    payroll_deductions: "-$1,100.00",
    payroll_overtime_amount: "+$342.50",
    payroll_base_salary: "$5,200.00",
    payroll_allowance: "+$420.00",
    payroll_tax: "-$1,100.00",
    payroll_tax_label: "Standard statutory (18.4%)",
    payroll_total: "$4,862.50",
    approver_name: "Sample Approver (HR Lead)",
    approver_initials: "SA"
  }.freeze

  STATUS_BADGE_CLASSES = {
    "present" => "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300",
    "half day" => "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
    "late" => "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300",
    "absent" => "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300",
    "missing checkout" => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300"
  }.freeze

  PAYROLL_STATUS_CLASSES = {
    "draft" => "bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300",
    "approved" => "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300",
    "paid" => "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300"
  }.freeze

  EMPLOYEE_TYPE_LABELS = {
    "owner" => "Owner",
    "full_time" => "Full-Time",
    "part_time" => "Part-Time",
    "contractor" => "Contractor",
    "intern" => "Intern"
  }.freeze

  BUSINESS_TYPE_LABELS = {
    "onsite_miss" => "Onsite Miss",
    "remote_work" => "Remote Work",
    "field_work" => "Field Work"
  }.freeze

  def mobile_preview(key)
    PREVIEW.fetch(key.to_sym, "—")
  end

  def mobile_sample_badge
    tag.span("Sample", class: "inline-flex items-center rounded-full bg-amber-100 px-2 py-0.5 text-xs font-semibold text-amber-800 dark:bg-amber-900/30 dark:text-amber-300")
  end

  def mobile_greeting(name)
    first_name = name.to_s.split.first.presence || "there"
    hour = Time.current.hour
    salutation =
      if hour >= 5 && hour < 12
        "Good morning"
      elsif hour >= 12 && hour < 18
        "Good afternoon"
      else
        "Good evening"
      end
    "#{salutation}, #{first_name}"
  end

  def mobile_initials(name)
    parts = name.to_s.split
    return "?" if parts.empty?

    parts.map { |part| part[0] }.join[0, 2].upcase
  end

  def mobile_duration(minutes)
    total = minutes.to_i
    format("%dh %02dm", total / 60, total % 60)
  end

  def mobile_duration_from_seconds(seconds)
    mobile_duration(seconds.to_i / 60)
  end

  def mobile_time(datetime)
    return "—" if datetime.blank? || !datetime.respond_to?(:in_time_zone)

    datetime.in_time_zone.strftime("%I:%M %p")
  end

  def mobile_date(date)
    return "—" if date.blank?

    date.to_date.strftime("%d %B %Y")
  end

  def mobile_weekday(date)
    return "—" if date.blank?

    date.to_date.strftime("%a")
  end

  def mobile_month_label(date)
    return "—" if date.blank?

    date.to_date.strftime("%B %Y")
  end

  def mobile_month_param(date)
    return nil if date.blank?

    date.to_date.strftime("%Y-%m")
  end

  def mobile_attendance_rate(month)
    return "—" if month.blank?

    total = month.total_records.to_i
    return "—" if total.zero?

    format("%.1f%%", month.total_present_days.to_f / total * 100)
  end

  def mobile_attendance_status_badge(status)
    label = status.to_s.humanize.presence || "—"
    classes = STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300")
    tag.span(label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}")
  end

  def mobile_payroll_status_badge(status)
    label = status.to_s.humanize.presence || "—"
    classes = PAYROLL_STATUS_CLASSES.fetch(status.to_s, "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300")
    tag.span(label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{classes}")
  end

  def mobile_employee_type_label(type)
    EMPLOYEE_TYPE_LABELS.fetch(type.to_s, type.to_s.humanize)
  end

  def mobile_business_type_label(type)
    BUSINESS_TYPE_LABELS.fetch(type.to_s, type.to_s.humanize)
  end
end
