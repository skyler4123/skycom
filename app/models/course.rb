# frozen_string_literal: true

# Course — Atomic purpose: an internal training course made of ordered lessons.
#
# Why it exists: compliance and onboarding training has to be assigned, completed and re-proved on expiry; an exam alone cannot express 'read these five lessons then pass the test'.
# How it works: course header with category/status; lessons are CourseLessons. Completion is tracked per employee in CourseEnrollments, which can point at an Exam for the assessment half. This is deliberately separate from Exam, which remains the assessment engine.
# Main associations: belongs_to :company; has_many :course_lessons, :course_enrollments.
class Course < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :status, WORKFLOW_STATUS, prefix: true, default: :draft

  # --- Associations ---
  belongs_to :company
  has_many :course_lessons, dependent: :destroy
  has_many :course_enrollments, dependent: :restrict_with_error

  # --- Scopes ---
  scope :published, -> { where(status: :confirmed) }

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :company_id }
end
