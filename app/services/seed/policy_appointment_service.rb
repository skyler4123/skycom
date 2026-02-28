class Seed::PolicyAppointmentService
  def self.run
    Branch.all.each_with_index do |company, index|
      roles = branch.roles
      policies = branch.policies
      policies.each do |policy|
        policy.roles << roles.sample
      end
      roles.each do |role|
        role.policies << policies.sample
      end
    end
  end
end
