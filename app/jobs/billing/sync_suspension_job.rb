# frozen_string_literal: true

# Daily midnight job that suspends companies whose suspension_at has passed.
#
#   SyncSuspensionJob.perform
#
# A company is suspended when:
#   1. suspension_at is NOT null
#   2. suspension_at <= Time.current (the deadline has passed)
#   3. lifecycle_status is NOT already :suspended or :disabled
#
# The suspended lifecycle_status becomes the source of truth for
# check_accessable and is_accessible? — the company is redirected
# to the billing page and cannot use the platform until resolved.
#
module Billing
  class SyncSuspensionJob < ApplicationJob
    queue_as :default

    def perform
      Company.where.not(lifecycle_status: %i[suspended disabled])
             .where(suspension_at: ..Time.current)
              .find_each(batch_size: COMPANY_PROCESSING_BATCH_SIZE, &:mark_suspended!)
    end
  end
end
