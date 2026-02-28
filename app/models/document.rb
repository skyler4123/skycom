class Document < ApplicationRecord
  include TagConcern

  belongs_to :document_group
  belongs_to :company
  belongs_to :branch, optional: true
end
