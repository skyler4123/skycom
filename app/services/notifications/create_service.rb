# frozen_string_literal: true

# == Purpose:
# System-generated broadcast: one Notification row per event plus tag links.
# Employees subscribe via the same tags (EmployeeNotificationTagAppointment);
# no per-employee fan-out rows are written here.
#
# == Returns (never raises for business failures):
#   { success: true, notification: <Notification> } | { success: false, errors: ["..."] }
#
# Throttle: pass throttle_key + throttle_window to collapse bursts
# (e.g. stock-low firing 20x/min creates 1 row, not 20).
module Notifications
  class CreateService
    def self.call(company:, title:, tag_ids:, body: nil, severity: :info, url: nil,
      throttle_key: nil, throttle_window: nil)
      new(company: company, title: title, body: body, severity: severity, url: url,
        tag_ids: tag_ids, throttle_key: throttle_key,
        throttle_window: throttle_window).call
    end

    def initialize(company:, title:, tag_ids:, body:, severity:, url:, throttle_key:, throttle_window:)
      @company = company
      @title = title
      @body = body
      @severity = severity
      @url = url
      @tag_ids = Array(tag_ids)
      @throttle_key = throttle_key
      @throttle_window = throttle_window
    end

    def call
      return failure("Title is required") if @title.to_s.strip.empty?
      return failure("At least one tag is required") if @tag_ids.empty?

      tags = NotificationTag.where(company: @company, id: @tag_ids)
      return failure("Unknown notification tags") if tags.size != @tag_ids.uniq.size

      notification = nil
      # Serialize per company so concurrent throttled bursts cannot slip
      # multiple rows through the check-then-insert window.
      @company.with_lock do
        return failure("Throttled duplicate notification") if throttled?

        ActiveRecord::Base.transaction(requires_new: true) do
          notification = Notification.create!(
            company: @company, title: @title, body: @body, severity: @severity, url: @url,
            metadata: @throttle_key.present? ? { "throttle_key" => @throttle_key } : {}
          )
          rows = @tag_ids.map do |tag_id|
            { company_id: @company.id,
              notification_id: notification.id, notification_tag_id: tag_id,
              created_at: Time.current, updated_at: Time.current }
          end
          NotificationTagAppointment.insert_all!(rows)
        end
      end

      invalidate_subscriber_caches!
      publish_event(notification)
      { success: true, notification: notification }
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.join(", "))
    end

    private

    def throttled?
      return false if @throttle_key.blank? || @throttle_window.blank?

      Notification
        .joins(:notification_tag_appointments)
        .where(company: @company)
        .where(notification_tag_appointments: { notification_tag_id: @tag_ids })
        .where("notifications.metadata ->> 'throttle_key' = ?", @throttle_key)
        .where("notifications.created_at >= ?", @throttle_window.ago)
        .exists?
    end

    def invalidate_subscriber_caches!
      employee_ids = EmployeeNotificationTagAppointment
        .where(company: @company, notification_tag_id: @tag_ids)
        .distinct.pluck(:employee_id)
      employee_ids.each do |employee_id|
        Rails.sync_cache.delete(Notifications::UnreadQuery.cache_key(employee_id))
      end
    end

    def publish_event(notification)
      WEBSOCKET.publish_event(
        channel: WEBSOCKET.channel_name(:company, @company&.id),
        event_key: :notification_created,
        data: { id: notification.id, tag_ids: @tag_ids }
      )
    rescue StandardError => e
      Rails.logger.warn("[Notifications::CreateService] WS publish failed: #{e.message}")
    end

    def failure(message)
      { success: false, errors: [ message ] }
    end
  end
end
