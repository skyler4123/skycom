# spec/support/active_job_matchers.rb
RSpec.configure do |config|
  config.around(:each, :active_job) do |example|
    original = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original
  end
end
