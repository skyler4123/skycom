require "rails_helper"

RSpec.describe PromoCampaigns::DueSweeperJob, type: :job do
  it "enqueues only due scheduled campaigns" do
    due = create(:promo_campaign, status: :scheduled, scheduled_at: 1.hour.ago)
    future = create(:promo_campaign, status: :scheduled, scheduled_at: 1.hour.from_now)
    draft = create(:promo_campaign, status: :draft, scheduled_at: 1.hour.ago)

    expect {
      described_class.perform_now
    }.to change { SolidQueue::Job.where(class_name: "PromoCampaignJob").count }.by(1)

    enqueued_ids = SolidQueue::Job.where(class_name: "PromoCampaignJob")
      .map { |job| Array(job.arguments["arguments"] || job.arguments[:arguments]).first }
    expect(enqueued_ids).to eq([ due.id ])
    expect(future.reload).to be_status_scheduled
    expect(draft.reload).to be_status_draft
  end

  it "recovers campaigns stuck in processing" do
    stuck = create(:promo_campaign, status: :processing)
    stuck.update_column(:updated_at, 20.minutes.ago)
    fresh = create(:promo_campaign, status: :processing)

    described_class.perform_now

    expect(stuck.reload).to be_status_scheduled
    expect(fresh.reload).to be_status_processing
    enqueued_ids = SolidQueue::Job.where(class_name: "PromoCampaignJob")
      .map { |job| Array(job.arguments["arguments"] || job.arguments[:arguments]).first }
    expect(enqueued_ids).to include(stuck.id)

    PromoCampaignJob.perform_now(stuck.id)
    expect(stuck.reload).to be_status_completed
  end
end
