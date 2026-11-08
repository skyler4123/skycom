# frozen_string_literal: true

# Reception::ParcelService — persists front-desk parcels as Events flagged with
# `metadata["reception_kind"] = "parcel"`, linked to the recipient employee
# through EmployeeEventAppointment. The console filters these Events out of the
# visitor queue and shows them in the Couriers & Deliveries panel instead.
# Docs: docs/OPERATIONS.md, docs/EVENTS.md
class Reception::ParcelService
  def self.create(company:, appointment:, params:, now: Time.current)
    new(company: company, appointment: appointment, params: params, now: now).create
  end

  def self.notify(company:, appointment:, parcel_id:, now: Time.current)
    new(company: company, appointment: appointment, params: {}, now: now).notify(parcel_id)
  end

  def self.pick_up(company:, appointment:, parcel_id:, now: Time.current)
    new(company: company, appointment: appointment, params: {}, now: now).pick_up(parcel_id)
  end

  def initialize(company:, appointment:, params:, now:)
    @company = company
    @appointment = appointment
    @params = params
    @now = now
  end

  def create
    carrier = params[:carrier].to_s.strip
    item = params[:item].to_s.strip
    employee = company.employees
      .where("branch_id = ? OR branch_id IS NULL", appointment.branch_id)
      .find_by(id: params[:employee_id])

    return failure([ "Carrier is required." ]) if carrier.blank?
    return failure([ "Item summary is required." ]) if item.blank?
    return failure([ "Recipient is required." ]) unless employee

    code = "PKG-#{SecureRandom.hex(3).upcase}"
    event = company.events.new(
      name: "Parcel #{code}",
      code: code,
      business_type: :appointment,
      workflow_status: :received,
      category: category,
      branch: appointment.branch,
      start_at: now,
      metadata: {
        "reception_kind" => "parcel",
        "carrier" => carrier,
        "item" => item,
        "recipient_name" => employee.name,
        "locker" => "Held at desk",
        "received_at" => now.iso8601
      }
    )

    ActiveRecord::Base.transaction do
      event.save!
      EmployeeEventAppointment.create!(company: company, event: event, employee: employee)
    end

    {
      success: true,
      event: event.reload,
      message: "Parcel logged for #{employee.name}. The recipient can be notified."
    }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.presence || [ e.message ])
  end

  def notify(parcel_id)
    event = find_parcel(parcel_id)
    return failure([ "Parcel not found." ]) unless event

    metadata = (event.metadata || {}).dup
    metadata["notified_at"] = now.iso8601
    event.update!(metadata: metadata)

    recipient = event.employee_event_appointments.first&.employee&.name.presence ||
      metadata["recipient_name"].presence || "recipient"

    { success: true, event: event, message: "Pickup notification sent for #{recipient}." }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.presence || [ e.message ])
  end

  def pick_up(parcel_id)
    event = find_parcel(parcel_id)
    return failure([ "Parcel not found." ]) unless event

    metadata = (event.metadata || {}).dup
    metadata["picked_up_at"] = now.iso8601
    event.update!(workflow_status: :completed, metadata: metadata)

    recipient = event.employee_event_appointments.first&.employee&.name.presence ||
      metadata["recipient_name"].presence || "recipient"

    { success: true, event: event, message: "Parcel marked as picked up by #{recipient}." }
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages.presence || [ e.message ])
  end

  private

  attr_reader :company, :appointment, :params, :now

  def find_parcel(parcel_id)
    event = company.events.find_by(id: parcel_id, branch_id: appointment.branch_id)
    return nil unless event
    return nil unless event.metadata&.dig("reception_kind") == "parcel"

    event
  end

  def category
    @category ||= Category.find_or_create_by!(
      company: company,
      resource_name: "events",
      name: "Parcels"
    )
  end

  def failure(errors)
    { success: false, errors: Array(errors) }
  end
end
