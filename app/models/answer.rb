# frozen_string_literal: true

# Answer — Atomic purpose: one answer option or response belonging to a Question.
#
# Why it exists: separates answer content from the question so multiple options
# or responses can be stored with their own category/property schema.
# How it works: belongs to company, question, category, and property mapping;
# tags and dynamic search come from concerns.
# Main associations: belongs_to :company, :question, :category,
# :property_mapping (required).
class Answer < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include DynamicSearchConcern
  include TagConcern

  belongs_to :company
  belongs_to :question
  belongs_to :category
  belongs_to :property_mapping
end
