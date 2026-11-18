# frozen_string_literal: true

# CourseLesson — Atomic purpose: one ordered lesson inside a course, with its written content.
#
# Why it exists: training content must live in discrete, ordered units so progress can be recorded and an employee can resume where they stopped; one big markdown blob cannot answer 'which lessons are done'.
# How it works: ordered child rows with markdown body and an expected duration. Position is unique per course. Media lives in StoredFiles attached separately, keeping this row about the lesson itself.
# Main associations: belongs_to :company, :course.
class CourseLesson < ApplicationRecord
include SetDefaultCompanyConcern

  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Associations ---
  belongs_to :company
  belongs_to :course

  # --- Scopes ---
  scope :ordered, -> { order(:position) }

  # --- Validations ---
  validates :title, presence: true, length: { maximum: 255 }
  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :course_id }
end
