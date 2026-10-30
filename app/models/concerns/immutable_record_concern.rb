# frozen_string_literal: true

# ImmutableRecordConcern — Atomic purpose: blocks update and destroy for shared
# reference rows.
#
# Why it exists: records such as Address and Membership are shared by many
# owners; editing or deleting them would rewrite history for everyone.
# How it works: before_update/before_destroy raise ActiveRecord::ReadOnlyRecord;
# callers must create a new row instead.
# Main associations: none directly.
module ImmutableRecordConcern
  extend ActiveSupport::Concern

  included do
    # 1. Block Updates
    before_update :prevent_modification

    # 2. Block Deletion
    before_destroy :prevent_modification
  end

  private

  def prevent_modification
    # This raises a specific error that stops the transaction immediately.
    raise ActiveRecord::ReadOnlyRecord, "#{self.class} is shared and immutable. You can only create new records."
  end
end
