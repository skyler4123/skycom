# frozen_string_literal: true

# Question — Atomic purpose: one reusable question definition in the exam/assessment
# catalog.
#
# Why it exists: questions are shared across exams and need their own dynamic
# category schema; answers reference the question.
# How it works: belongs to company, optional branch, category, and property
# mapping; tags and dynamic search come from concerns.
# Main associations: belongs_to :company, :category, :property_mapping (required),
# :branch (optional).
class Question < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
end
