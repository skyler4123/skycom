class Document < ApplicationRecord
  belongs_to :document_group
  belongs_to :company_group
  belongs_to :company
end
