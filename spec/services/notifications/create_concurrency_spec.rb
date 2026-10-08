require "rails_helper"

RSpec.describe "Notifications::CreateService concurrency" do
  let(:company) { create(:company) }
  let(:tag) { NotificationTag.create!(company: company, name: "ops") }

  it "creates exactly one row under a concurrent throttled burst" do
    results = Queue.new
    threads = 5.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          results << Notifications::CreateService.call(company: company, title: "burst",
            tag_ids: [ tag.id ], throttle_key: "burst:1", throttle_window: 1.hour)
        end
      end
    end
    threads.each(&:join)

    successes = [].tap { |a| a << results.pop until results.empty? }.count { |r| r[:success] }
    expect(successes).to eq(1)
    expect(Notification.where(company: company).count).to eq(1)
  end
end
