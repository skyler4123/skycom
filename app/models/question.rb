# frozen_string_literal: true

# Question — Atomic purpose: one reusable question in a company's question bank.
#
# Why it exists: questions are pooled and reused across exams, with a type, points,
# and a correct answer that never changes an existing attempt (attempts snapshot it).
# How it works: belongs to company and a "questions" category; has many options for
# single-choice/true-false questions, or a correct_text for text questions. Exam
# links are atomic join rows.
# Main associations: belongs_to :company, :category; has_many :question_options,
# :exam_question_appointments, :exams through, :employee_question_appointments.
class Question < ApplicationRecord
  attribute :permission_resource_name, :string, default: -> { self.name }

  # --- Enums ---
  enum :question_type, { single_choice: 0, true_false: 1, text: 2 }, prefix: true
  enum :lifecycle_status, LIFECYCLE_STATUS, prefix: true

  # --- Associations ---
  belongs_to :company
  belongs_to :category

  has_many :question_options, -> { order(:position) }, dependent: :destroy, inverse_of: :question
  has_many :exam_question_appointments, dependent: :destroy
  has_many :exams, through: :exam_question_appointments
  has_many :employee_question_appointments, dependent: :destroy

  # --- Validations ---
  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :question_type, presence: true
  validates :points, numericality: { only_integer: true, greater_than: 0 }
  validate :category_is_question_category
  validate :options_match_type

  def single_choice?
    question_type_single_choice?
  end

  def true_false?
    question_type_true_false?
  end

  def text?
    question_type_text?
  end

  def choice?
    single_choice? || true_false?
  end

  def shuffleable?
    single_choice?
  end

  def correct_option
    question_options.find(&:correct?)
  end

  private

  def category_is_question_category
    return if category.blank? || company.blank?

    errors.add(:category, "must belong to the same company") if category.company_id != company_id
    errors.add(:category, "must be a question category") unless category.resource_name == "questions"
  end

  def options_match_type
    options = question_options.reject(&:marked_for_destruction?)

    if text?
      errors.add(:question_options, "must be empty for text questions") if options.any?
      return
    end

    errors.add(:correct_text, "must be blank for choice questions") if correct_text.present?
    errors.add(:question_options, "must have at least two options") if options.size < 2
    errors.add(:question_options, "must have exactly one correct option") unless options.count(&:correct?) == 1
    errors.add(:question_options, "must have exactly two options") if true_false? && options.size != 2
  end
end
