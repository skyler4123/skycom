class DemoJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Demo Rails.logger.info in DemoJob")
    sleep 5 # Simulate a long-running job
    WEBSOCKET.publish(
      channel: "company_1_notifications",
      data: { text: "Duplicate stream bug crushed!" }
    )
    true
  end
end
