class Document < ApplicationRecord
  include TagConcern

  belongs_to :document_group
  belongs_to :company_group
  belongs_to :company
end
