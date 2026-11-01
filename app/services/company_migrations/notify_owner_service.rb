# frozen_string_literal: true

# Owner notification for a CompanyMigration event: find-or-create the system
# "Migrations" tag, subscribe the owner, then delegate to
# Notifications::CreateService (throttled so retries cannot spam the owner).
# Mirrors Companies::WelcomeNotificationJob's tag/subscribe pattern.
module CompanyMigrations
  class NotifyOwnerService
    def self.call(company:, name:, description:, severity: :info, throttle_key:, throttle_window: 24.hours)
      new(
        company: company,
        name: name,
        description: description,
        severity: severity,
        throttle_key: throttle_key,
        throttle_window: throttle_window
      ).call
    end

    def initialize(company:, name:, description:, severity:, throttle_key:, throttle_window:)
      @company = company
      @name = name
      @description = description
      @severity = severity
      @throttle_key = throttle_key
      @throttle_window = throttle_window
    end

    def call
      owner = @company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)
      return { success: false, errors: [ "owner not found" ] } if owner.nil?

      tag = NotificationTag.find_or_create_by!(company: @company, name: MIGRATION_NOTIFICATION_TAG) do |record|
        record.description = "Migration progress for the company owner."
        record.business_type = :system
      end
      EmployeeNotificationTagAppointment.find_or_create_by!(
        company: @company, employee: owner, notification_tag: tag
      )

      Notifications::CreateService.call(
        company: @company,
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
