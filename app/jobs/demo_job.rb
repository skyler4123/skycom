class DemoJob < ApplicationJob
  queue_as :default
  # self.queue_adapter = :solid_queue

  def perform
    sleep 5 # Simulate a long-running job
    puts "DemoJob is 22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222"
  end
end
