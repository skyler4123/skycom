# frozen_string_literal: true

# QuestionOption — Atomic purpose: one selectable choice for a question.
#
# Why it exists: single-choice and true/false questions need ordered choices with
# exactly one correct answer; text questions have none.
# How it works: belongs to a question; company is derived from the question.
# Main associations: belongs_to :company, :question.
class QuestionOption < ApplicationRecord
  include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :question, inverse_of: :question_options

  # --- Validations ---
  validates :content, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
