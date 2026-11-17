# frozen_string_literal: true

# CommentMention — Atomic purpose: records that one employee was @mentioned in one comment, and whether they saw it.
#
# Why it exists: an @mention is a notification request with its own read state: without a row, the bell cannot show 'you were mentioned' and a mention cannot be marked seen without marking the whole comment read.
# How it works: atomic pair between RecordComment and Employee with a read timestamp. Unique per pair so double-mentioning in one comment is idempotent. Company derives from the comment via SetDefaultCompanyConcern.
# Main associations: belongs_to :company, :record_comment, :employee.
class CommentMention < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :record_comment
  belongs_to :employee

  # --- Scopes ---
  scope :unread, -> { where(read_at: nil) }

  # --- Validations ---
  validates :employee_id, uniqueness: { scope: :record_comment_id }
end
