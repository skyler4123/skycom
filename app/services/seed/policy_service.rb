# This service seeds the database with Policy records, ensuring each policy
# is associated with an existing Company. It uses the enums defined in the Policy model
# and simulates soft deletion.

class Seed::PolicyService
  # Configuration for the number of policies per company
  POLICIES_PER_COMPANY = 6

  # Common resources and actions for creating realistic policy data
  COMMON_RESOURCES = %w[employees roles documents financial_data user_profiles]
  COMMON_ACTIONS = %w[read write delete update view approve]
  
  def self.run
    # Get the defined enum keys for random assignment
    statuses = Policy.statuses.keys
    kinds = Policy.kinds.keys
    
    Company.all.each do |company|
      POLICIES_PER_COMPANY.times do |i|
        random_kind = kinds.sample
        random_status = statuses.sample
        
        # Combine a resource and action for a descriptive policy name
        random_resource = COMMON_RESOURCES.sample
        random_action = COMMON_ACTIONS.sample

        # Create a unique name to satisfy the uniqueness validation
        policy_name = "#{random_action.capitalize} #{random_resource.titleize} Access Policy #{i + 1}"
        
        # Randomly discard about 1 in 10 records
        should_discard = rand(10) == 0
        
        Policy.create!(
          company: company,
          name: policy_name,
          description: "Policy governing the #{random_action} access to #{random_resource}.", 
          resource: random_resource.singularize,
          action: random_action,
          kind: random_kind, 
          status: random_status,
          # Set a random discarded_at time if the record should be discarded
          discarded_at: should_discard ? Time.zone.now - rand(1..90).days : nil
        )
      end
    end
  end
end