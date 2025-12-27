# app/models/concerns/immutable_record.rb
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
