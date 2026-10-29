# frozen_string_literal: true

# Formatting and labelling helpers for the server-rendered /mobile pages.
module MobileHelper
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

  def mobile_money(cents, currency = :usd)
    amount = cents.to_i / 100.0

    if currency.to_s == "vnd"
      number_to_currency(amount, unit: "₫", precision: 0, format: "%n %u")
    else
      number_to_currency(amount, unit: "$", precision: 2)
    end
  end

  def mobile_payroll_tax_label
    format("Statutory (%.1f%%)", (PAYROLL_TAX_RATE + PAYROLL_SOCIAL_INSURANCE_RATE) * 100)
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

  def mobile_time(datetime, utc_offset: nil)
    return "—" if datetime.blank? || !datetime.respond_to?(:in_time_zone)

    time = datetime.in_time_zone
    time = time.getlocal(utc_offset) if utc_offset
    time.strftime("%I:%M %p")
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
