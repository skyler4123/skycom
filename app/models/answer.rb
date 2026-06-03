class Answer < ApplicationRecord
  include CategoryConcern
  include PropertyMappingConcern
  include TagConcern

  belongs_to :company
  belongs_to :question
  belongs_to :category
  belongs_to :property_mapping
end
