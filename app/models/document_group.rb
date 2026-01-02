class DocumentGroup < ApplicationRecord
  include TagConcern

  belongs_to :company_group
  belongs_to :company
end
