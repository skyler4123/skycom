# frozen_string_literal: true

# Notifies the employee who created an Import (not necessarily the owner) about
# a finished run or rollback. Uses the system "Imports" tag and delegates to
# Notifications::CreateService with a throttle so retries cannot spam.
module Imports
  class NotifyCreatorService
    def self.call(import:, name:, description:, severity: :info, throttle_key:, throttle_window: 24.hours)
      new(
        import: import,
        name: name,
        description: description,
        severity: severity,
        throttle_key: throttle_key,
        throttle_window: throttle_window
      ).call
    end

    def initialize(import:, name:, description:, severity:, throttle_key:, throttle_window:)
      @import = import
      @name = name
      @description = description
      @severity = severity
      @throttle_key = throttle_key
      @throttle_window = throttle_window
    end

    def call
      employee = @import.creator
      return { success: false, errors: [ "creator not found" ] } if employee.nil?

      tag = NotificationTag.find_or_create_by!(company: @import.company, name: IMPORT_NOTIFICATION_TAG) do |record|
        record.description = "Import progress notifications."
        record.business_type = :system
      end
      EmployeeNotificationTagAppointment.find_or_create_by!(
        company: @import.company, employee: employee, notification_tag: tag
      )

      Notifications::CreateService.call(
        company: @import.company,
        name: @name,
        description: @description,
        tag_ids: [ tag.id ],
        severity: @severity,
        throttle_key: @throttle_key,
        throttle_window: @throttle_window
      )
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
