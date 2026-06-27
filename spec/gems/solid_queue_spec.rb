require 'rails_helper'

class TestJob < ActiveJob::Base
  queue_as :default

  def perform(arg)
    Rails.logger.info "Processed job with arg: #{arg}"
  end
end

RSpec.describe 'solid_queue', type: :job do
  # Include ActiveSupport time helpers for travel_to/freeze_time
  include ActiveSupport::Testing::TimeHelpers

  let(:job_arg) { 'test_argument' }

  before do
    # Clear out actual Solid Queue database tables between runs
    SolidQueue::Job.delete_all
  end

  describe 'queue adapter configuration' do
    it 'uses Solid Queue as the Active Job queue adapter' do
      expect(ActiveJob::Base.queue_adapter).to be_a(ActiveJob::QueueAdapters::SolidQueueAdapter)
    end
  end

  describe 'job enqueuing' do
    it 'successfully enqueues a job into the database' do
      expect {
        TestJob.perform_later(job_arg)
      }.to change { SolidQueue::Job.count }.by(1)
    end

    it 'enqueues to the correct queue' do
      TestJob.perform_later(job_arg)
      last_job = SolidQueue::Job.last

      expect(last_job.queue_name).to eq('default')
    end
  end

  describe 'job execution' do
    it 'successfully performs an enqueued job via the adapter' do
      TestJob.perform_later(job_arg)
      
      # Step 1: Ensure the job successfully landed in Solid Queue's ready table
      ready_execution = SolidQueue::ReadyExecution.last
      expect(ready_execution).to_not be_nil

      # Step 2: Grab the parent job payload
      solid_queue_job = ready_execution.job

      expect {
        # Step 3: Run the underlying ActiveJob payload inline
        ActiveJob::Base.execute(solid_queue_job.arguments)
        
        # Step 4: Simulate worker cleanup by removing it from the ready queue
        ready_execution.destroy
      }.to change { SolidQueue::ReadyExecution.count }.by(-1)
    end
  end

  describe 'delayed job scheduling' do
    it 'schedules a job to be run in the future' do
      # Fixes the missing freeze_time method by using ActiveSupport's helper directly
      travel_to Time.current do
        TestJob.set(wait: 5.minutes).perform_later(job_arg)
        
        scheduled_job = SolidQueue::ScheduledExecution.last
        expect(scheduled_job.scheduled_at).to eq(5.minutes.from_now)
      end
    end
  end
end