class PromoCampaignJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = PromoCampaign.find(campaign_id)
    PromoCampaigns::ExecuteService.call(campaign: campaign)
  end
end
