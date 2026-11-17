# frozen_string_literal: true

# RecordComment — Atomic purpose: one discussion message attached to any business record, with its author.
#
# Why it exists: context is lost when a question about an invoice lives in a chat app: 'why was this discounted' must be answerable on the invoice. Ticket comments already prove the value; this is the same capability for every other record type.
# How it works: `subject_type`/`subject_id` is polymorphic because the set of discussable records grows with every module — the same immutable-reference precedent as WorkflowStepLog#subject, and deliberately NOT an appointment. Mentions are CommentMention rows so notification fan-out stays a query.
# Main associations: belongs_to :company, :employee, :subject (polymorphic); has_many :comment_mentions.
class RecordComment < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :employee
  belongs_to :subject, polymorphic: true
  has_many :comment_mentions, dependent: :destroy

  # --- Scopes ---
  scope :recent_first, -> { order(created_at: :desc) }

  # --- Validations ---
  validates :body_markdown, presence: true, length: { maximum: 20_000 }
end
