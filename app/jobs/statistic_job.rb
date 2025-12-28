class StatisticJob < ApplicationJob
  queue_as :statistic_job

  def perform
    # 1. Get the current UTC hour (0-23)
    current_utc_hour = Time.current.utc.hour

    # 2. Find all companies that match their timezone with current UTC hour
    # Example: Timezone +7 will run when current UTC hour is 7
    # We also filter by discarded_at: nil to ensure we only process active companies
    companies = Company.where(timezone: current_utc_hour, discarded_at: nil)

    companies.find_each do |company|
      # 3. Calculate the total employees of this company
      total_employees = Employee.where(company: company, discarded_at: nil).count

      # 4. Store total employee into data field of Statistic model
      Statistic.create!(
        owner: company,
        data: { total_employees: total_employees },
        recorded_at: Time.current
      )
    end
  end
end
