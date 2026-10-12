# frozen_string_literal: true

# Delayed welcome for a new company — enqueued at the end of
# Company#initialize_company (covers every business_type and system
# companies alike). Country-versioned (WELCOME_NOTIFICATION_CONTENT),
# business-domain agnostic. Owner-only via a dedicated system tag so the
# row never leaks into other employees' history. Idempotent via
# throttle_key — retries and double-enqueues create nothing.
module Companies
  class WelcomeNotificationJob < ApplicationJob
    # Single-file constant: only used here (see docs/CONSTANTS.md).
    OWNER_WELCOME_TAG = "Owner Welcome".freeze

    queue_as :default

    def perform(company_id)
      company = Company.find_by(id: company_id)
      return if company.nil?

      owner = company.employees.find_by(business_type: OWNER_BUSINESS_TYPE)
      return if owner.nil?

      tag = NotificationTag.find_or_create_by!(company: company, name: OWNER_WELCOME_TAG) do |t|
        t.description = "Welcome and onboarding messages for the company owner."
        t.business_type = :system
      end
      EmployeeNotificationTagAppointment.find_or_create_by!(
        company: company, employee: owner, notification_tag: tag
      )

      content = WELCOME_NOTIFICATION_CONTENT[company.country&.to_sym] || WELCOME_NOTIFICATION_CONTENT[:us]
      result = Notifications::CreateService.call(
        company: company,
        title: content[:title],
        body: content[:body],
        tag_ids: [ tag.id ],
        severity: :info,
        throttle_key: "welcome:#{company.id}",
        throttle_window: 24.hours
      )
      Rails.logger.warn("[Companies::WelcomeNotificationJob] #{result[:errors].join(', ')}") unless result[:success]
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
