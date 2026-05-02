# app/models/concerns/membership_concern.rb
module MembershipConcern
  extend ActiveSupport::Concern

  included do
    has_many :membership_appointments, as: :appoint_to, dependent: :destroy
    
    # All memberships ever held
    has_many :memberships, through: :membership_appointments, source: :membership

    # Current appointments for all business types
    has_many :current_membership_appointments, -> { 
              where(lifecycle_status: :active) 
            }, 
            as: :appoint_to, 
            class_name: "MembershipAppointment"

    # Quick access to the most recent active membership
    has_one :latest_membership_appointment, -> { 
              where(lifecycle_status: :active)
              .order(created_at: :desc) 
            }, 
            as: :appoint_to, 
            class_name: "MembershipAppointment"

    has_one :db_membership, through: :latest_membership_appointment, source: :membership
  end

  # Getter: Returns the most recent active Membership
  def membership
    cache_key = "#{cache_key_with_version}/current_membership"
    Rails.cache.fetch(cache_key) { db_membership }
  end

  # Setter: Defaults to :primary if no context is given
  def membership=(code)
    return if code.blank?
    attach_membership(code)
  end

  def attach_membership(code, business_type: :primary, **options)
    target_membership = Membership.find_by!(code: code)

    self.transaction do
      # 1. Archive ONLY the old membership of the SAME business_type
      # This allows a customer to be "Gold" (loyalty) AND "Pro" (subscription)
      membership_appointments.where(business_type: business_type)
                            .where(lifecycle_status: :active)
                            .update_all(lifecycle_status: :archived)

      # 2. Create the new appointment
      membership_appointments.create!(
        membership:       target_membership,
        business_type:    business_type,
        appoint_from:     options[:from],
        appoint_for:      options[:for],
        appoint_by:       options[:by],
        lifecycle_status: :active,
        workflow_status:  options[:workflow_status] || :approved
      )
      
      # 3. Cache Invalidation
      self.touch if self.persisted?
    end
  end

  # Helper to get membership by specific type
  def membership_of_type(type)
    cache_key = "#{cache_key_with_version}/membership_#{type}"
    Rails.cache.fetch(cache_key) do
      membership_appointments.active.send(type).first&.membership
    end
  end
end


# customer = Customer.find(id)

# # 1. Set Loyalty Tier
# customer.attach_membership("gold_tier", business_type: :loyalty)

# # 2. Set Subscription Track (Doesn't archive the Loyalty Tier!)
# customer.attach_membership("pro_plan", business_type: :subscription)

# # 3. Retrieve specific memberships
# customer.membership_of_type(:loyalty)      # => <Membership: Gold>
# customer.membership_of_type(:subscription) # => <Membership: Pro>

# # 4. Default getter (the most recent one attached)
# customer.membership # => <Membership: Pro>