# frozen_string_literal: true

# ExamGroup — Atomic purpose: company-scoped grouping of exams.
#
# Why it exists: organizes exams into a catalog or series and carries the shared
# category/property schema for its exams.
# How it works: belongs to company, optional branch, category, and property
# mapping; exams reference the group.
# Main associations: belongs_to :company, :category, :property_mapping (required),
# :branch (optional).
class ExamGroup < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  belongs_to :company
  belongs_to :branch, optional: true
  belongs_to :category
  belongs_to :property_mapping
end
