class Answer < ApplicationRecord
  include TagConcern

  belongs_to :company
  belongs_to :question
end
