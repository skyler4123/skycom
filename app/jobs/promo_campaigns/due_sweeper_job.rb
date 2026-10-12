module PromoCampaigns
  class DueSweeperJob < ApplicationJob
    queue_as :default

    # Single-file constant: a processing campaign untouched this long is
    # assumed killed mid-run (deploys, OOM, request timeout on run_now).
    STALE_PROCESSING_AFTER = 15.minutes

    def perform
      PromoCampaign.where(status: :processing).where("updated_at < ?", STALE_PROCESSING_AFTER.ago).find_each do |campaign|
        campaign.update!(status: :scheduled)
      end
      PromoCampaign.where(status: :scheduled).where("scheduled_at <= ?", Time.current).find_each do |campaign|
        PromoCampaignJob.perform_later(campaign.id)
      end
    end
  end
end
