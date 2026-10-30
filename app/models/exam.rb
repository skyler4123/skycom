# frozen_string_literal: true

# Exam — Atomic purpose: one exam/assessment definition that employees can be
# assigned to.
#
# Why it exists: HR training and compliance need a reusable exam record with its
# own category/property schema and employee assignments.
# How it works: belongs to an ExamGroup, company, optional branch, category, and
# property mapping; employees join through EmployeeExamAppointment. Tags and
# dynamic search come from concerns.
# Main associations: belongs_to :exam_group, :company, :category,
# :property_mapping (required), :branch (optional); has_many :employees through
# :employee_exam_appointments (dependent: :destroy).
class Exam < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  belongs_to :exam_group
  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping

  has_many :employee_exam_appointments, dependent: :destroy
  has_many :employees, through: :employee_exam_appointments
end
