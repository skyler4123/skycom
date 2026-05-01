# app/models/concerns/period_concern.rb
module PeriodConcern
  extend ActiveSupport::Concern

  included do
    has_many :period_appointments, as: :appoint_to, dependent: :destroy

    # Direct access to all unique Period records assigned to this model
    has_many :periods, through: :period_appointments, source: :period

    # Association for the primary active period (e.g., current subscription window)
    has_one :current_period_appointment, -> {
              where(lifecycle_status: :active)
              .order(created_at: :desc)
            },
            as: :appoint_to,
            class_name: "PeriodAppointment"

    has_one :db_period, through: :current_period_appointment, source: :period
  end

  # Returns the current Period record with caching
  def current_period
    cache_key = "#{cache_key_with_version}/current_period"
    Rails.cache.fetch(cache_key) { db_period }
  end

  # Setter: record.period = { start_at: Time.now, end_at: 1.month.from_now, timezone: :plus_7 }
  def period=(options)
    return if options.blank?
    attach_period(**options.symbolize_keys)
  end

  def attach_period(**attributes)
    # 1. Normalize attributes
    b_type = attributes[:business_type] || :base
    w_status = attributes[:workflow_status] || :approved
    l_status = :active

    # 2. Find or create the immutable Period record
    # This reuses existing periods if the start/end/timezone match exactly
    target_period = Period.find_or_create_by!(
      start_at: attributes[:start_at],
      end_at:   attributes[:end_at],
      timezone: attributes[:timezone] || :utc # or your default key
    )

    self.transaction do
      # 3. Archive old appointments of the SAME business type
      # (e.g., if updating the 'subscription' period, archive the old 'subscription' one)
      period_appointments.where(business_type: b_type)
                         .where(lifecycle_status: :active)
                         .update_all(lifecycle_status: :archived)

      # 4. Create the new appointment
      period_appointments.create!(
        period:           target_period,
        business_type:    b_type,
        lifecycle_status: l_status,
        workflow_status:  w_status,
        appoint_from:     attributes[:from],
        appoint_for:      attributes[:for],
        appoint_by:       attributes[:by],
        name:             attributes[:name],
        description:      attributes[:description]
      )

      self.touch if self.persisted?
    end
  end
end
