class Seed::PolicyAppointmentService
  def self.run
    Company.all.each_with_index do |company, index|
      roles = company.roles
      policies = company.policies
      policies.each do |policy|
        policy.roles << roles.sample
      end
      roles.each do |role|
        role.policies << policies.sample
      end
    end
  end
end
